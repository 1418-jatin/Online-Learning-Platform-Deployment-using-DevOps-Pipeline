# Use official NGINX base image
FROM nginx:latest

# Set working directory inside container
WORKDIR /usr/share/nginx/html

# Copy your custom application files (frontend or static site)
COPY ./index.html .

# Optional: replace default nginx config if needed
# COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# NGINX runs automatically as entrypoint
