server {

        # SSL configuration

        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        ssl_certificate         /etc/ssl/certs/cert.pem;
        ssl_certificate_key     /etc/ssl/private/key.pem;


        root /git/rs-docs/build;
        index index.html;

        server_name docs.regshort.com www.docs.regshort.com;

        location / {
                try_files $uri $uri/ =404;
        }
}