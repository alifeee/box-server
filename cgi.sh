#!/bin/bash
# CGI, i.e., generate HTML page with appropriate headers

echo "Content-type: text/html"
echo ""
(cd /usr/alifeee/box-server/; ./render.sh)
