FROM ghcr.io/martinthomson/i-d-template-action:latest

# Add inotify-tools for file watching in development
RUN apk add --no-cache inotify-tools

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["all"]
