server {
    listen 80;
    {{EXTRA_PORT}}
    server_name {{DOMAIN}};

    root /var/www/html/{{PROJECT_RELATIVE}}/public;
    index index.php index.html;

    access_log /var/log/nginx/{{DOMAIN}}.access.log;
    error_log /var/log/nginx/{{DOMAIN}}.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php-fpm:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /var/www/html/{{PROJECT_RELATIVE}}/public$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
    }

    location ~ /\.ht {
        deny all;
    }
}

