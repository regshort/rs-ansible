server {

	# SSL configuration

	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	ssl_certificate         /etc/ssl/certs/cert.pem;
	ssl_certificate_key     /etc/ssl/private/key.pem;

	server_name terminal.regshort.com www.terminal.regshort.com;

        location / {
	    proxy_pass http://127.0.0.1:3001;
            include proxy_params;
        }

}
