FROM nginx:alpine

# Copy the static site into nginx's default web root
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
