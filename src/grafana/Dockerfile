FROM grafana/grafana-oss:sha256:68a314e94efeb5553fa8734e71d0c534e4849c6f908e22db8238b1c0bbe3ac00

# Create a non-root user and group
RUN groupadd -g 1000 grafana && \
    useradd -u 1000 -g grafana -s /bin/bash -m grafana

# Change ownership of the Grafana directories
RUN chown -R grafana:grafana /usr/share/grafana /etc/grafana /var/lib/grafana

# Switch to the new user
USER grafana

# Expose the Grafana port
EXPOSE 3000

# Start Grafana
CMD ["grafana-server", "--volume=grafana-storage:/var/lib/grafana"]