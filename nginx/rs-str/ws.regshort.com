server {
   	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	ssl_certificate         /etc/ssl/certs/cert.pem;
	ssl_certificate_key     /etc/ssl/private/key.pem;

	server_name ws.regshort.com www.ws.regshort.com;

    location / {
        proxy_pass http://127.0.0.1:3333;
	    proxy_http_version 1.1;
        proxy_set_header Host $host;
        # These two lines are the key
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
