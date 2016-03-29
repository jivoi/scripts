#!/bin/bash 

# usage: ncat -l 8080 -e ./httpd.sh

### global variables that contain the configuration options ###
basedir="$PWD/webroot"
logfile="/tmp/httpd.log"
timeout="10"
###############################################################

log() {
	# use tail -f /tmp/httpd.log
	echo $@ >> "$logfile"
}

process_alive() {
	ps -o pid= --pid $1 &> /dev/null
}

kill_tree() {
	for child in $(ps -o pid= --ppid $1); do
		kill_tree $child
	done
	kill -9 $1
}

fork_with_timeout() {
    log "running $@"
    iters=0
    $@ 2>> $logfile &
    pid=$!
    log "forked CGI: $pid, waiting"
    while process_alive $pid; do 
	    if [ $iters -ge $((5*timeout)) ]; then
		    log "Killing $pid"
		    kill_tree $pid
		    break
	    fi
	    sleep 0.2
	    iters=$((iters+1))
    done
    log "Killer process on $pid exiting"
    wait $pid # && echo $?
}

upperx() {
    echo "$*" | tr 'a-z' 'A-Z' | tr -d '\r'
}

serve() {
    if [ ! -e "$(echo "${basedir}""${url}" | sed 's#%20#\ #g')" ]; then response "404 Not found" "$basedir$url"
    else
        if [ ! -r "$(echo "${basedir}""${url}" |   sed 's#%20#\ #g')" ]; then response "403 Forbidden" "$basedir$url"
            else
            response "200 OK" "${basedir}""${url}"
        fi
    fi
}

get_mime() {
	file="$1"
	mime=$(file --mime-type "$file" | sed 's#.*:\ ##')
	if [ $mime = "application/x-directory" -o $mime = "application/x-empty" ]; then mime="text/html"; fi
	echo $mime
}

add_header() {
    echo "$1" | egrep -i "^$2:" &>/dev/null || echo -en "$2: $3\r\n"
}

list_dir() {
                    echo "<table><tr><th>"
                    IFS=$(echo -en "\n\b")
                    for file in $(ls -1a "$path" | grep -v "^\.$"); do
                        [ -d "$path/$file" ] && file="$file/"
                        echo "<tr><td valign="top"><a href=\""$file"\">"$file"</a></td>"
                    done
                    unset IFS
                    echo "</th></tr></table>"
}

response() {
	code="$1"
        path="$(echo $2 | sed -e 's#\ #%20#g')"
        [[ "$code" != "200 OK" ]] && echo "$(upperx $http_version) $code";
	
	case "$code" in
		200*)
	        mime=$(get_mime "$path")
		if [ -d "$path" ]; then 
                    echo "$(upperx $http_version) $code";
                    tmpfile=$(mktemp)
                    echo $(list_dir "$path") > "$tmpfile"
		    echo -en "Content-Type: $mime; charset=utf-8\r\n"
		    echo -en "Connection: close\r\n"
		    echo -en "Content-Length: $(wc -c < "$tmpfile")\r\n\r\n"
		    cat "$tmpfile" && rm -f "$tmpfile"
	       elif [ -x "$path" ] && [[ "$path" =~ \.cgi$ ]]; then
                            tmpfile=$(mktemp)
                            cgiret=$(mktemp)
			    echo "$(fork_with_timeout "$path" ; echo "$?" > "$cgiret")" > "$tmpfile"
                            if [ "$(cat $cgiret)" != "0" ]; then
                                code="500 Internal Server Error"
                                rm -f $cgiret
                                echo "$(upperx $http_version) $code";
                                print_500
                            else
                                rm -f $cgiret
                                echo "$(upperx $http_version) $code";
			        if cat "$tmpfile" | tr -d '\r' | egrep '^$' &>/dev/null; then
			                log "Headers found."
				        headers="$(cat "$tmpfile" | sed -rn '1,/^\r*$/p')"
				        sed -ri '1,/^\r*$/d' "$tmpfile"
			        else
			                log "No headers found."
			        fi

			        add_header "$headers" "Content-Type"   "text/plain; charset=UTF-8"
			        add_header "$headers" "Content-Length" "$(wc -c < "$tmpfile")"
			        add_header "$headers" "Connection" "close"

			        echo "$headers"
			        cat $tmpfile && rm -f "$tmpfile"
                            fi
		else
                        echo "$(upperx $http_version) $code";
			echo -en "Content-Length: $(wc -c < "$path")\r\n";
			echo -en "Connection: close\r\n"
			echo -en "Content-Type: $mime\r\n\r\n";
			cat "$path" # FIXME: directory traversal?
		fi
		;;

		403*)
                    print_403
		;;
            	404*)
                    print_404
		;;
                501*)
                    print_501
                ;;  
	        *)
                    print_500
                ;;
	esac
}

print_403() {
### 403 forbidden ###
cat << 403
Content-Type:text/html; charset=utf-8
Connection: close

<html><head>
<title>403 Forbidden</title>
</head><body>
<h1>Forbidden</h1>
<p>You don't have permission to access $url
on this server.</p>
</body></html>
403
}

print_404() {
### 404 not found ###
cat << 404
Content-Type:text/html; charset=utf-8
Connection: close

<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL $url was not found on this server.</p>
</body></html>
404
}

print_500() {
# 500 Server Error
cat << 500
Content-Type:text/html; charset=utf-8
Connection: close

<html><head>
<title>500 Server error</title>
</head><body>
<h1>Server error</h1>
<p>Method not implemented or other misconfiguration occured.</p>
</body></html>
500
}

print_501() {
# 501 Not Implemented
cat << 501
Content-Type:text/html; charset=utf-8
<html><head>
<title>501 Not implemented</title>
</head><body>
<h1>Not Implemented</h1>
<p>Method not implemented or other misconfiguration occured.</p>
</body></html>
501
}

url_escape() {
 encoded=$(
   echo "$1" | hexdump -v -e '1/1 "%02x\t"' -e '1/1 "%_c\n"' |
   LANG=C awk '
     $1 == "20"                     { printf("%s",   "+");  next } 
     $1 ~  /0[adAD]/                {                       next } 
     $2 ~  /^[_a-zA-Z0-9.*()\/-]$/  { printf("%s",   $2);   next }
                                    { printf("%%%s", $1)         }
   ')
  echo "$encoded"
}

read method rest # url + http version
http_version=$(echo "$rest" | awk '{print $NF}')
rawurl=$(echo "$rest" | sed "s# $http_version\$##")
url=$(url_escape "$rawurl")

host="?"
while read header; do
	header="$(echo "$header" | tr -d '\r')"
	[ "$header" = "" ] && break

	[[ "$header" =~ ^[hH][oO][sS][tT] ]] && host="${header#*:}"
done

case "$(upperx $http_version)" in
  HTTP/1.0)
  ;;

  HTTP/1.1)
	log "Host: $host"
  ;;

  *)
    response 501 "Not Implemented" ""
    exit 1
  ;;
esac

case "$(upperx $method)" in
  GET)
    serve
  ;;

  POST) 
    response 501 "Not Implemented" ""
  ;;

  *)
   response 500 "Server error" ""
  ;;
esac
