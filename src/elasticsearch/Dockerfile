FROM docker.elastic.co/elasticsearch/elasticsearch:sha256-fffb0fb3d8305caded6bdfc7c2308133d3a67e71a4011e9867b9a2c3a7a3a7e5

# Set environment variables
ENV discovery.type=single-node

# Create a non-root user and group
RUN groupadd -g 1000 elasticsearch && \
    useradd -u 1000 -g elasticsearch -s /bin/bash -m elasticsearch

# Change ownership of the Elasticsearch directory
RUN chown -R elasticsearch:elasticsearch /usr/share/elasticsearch

# Switch to the non-root user
USER elasticsearch

# Expose the default Elasticsearch port
EXPOSE 9200

# Run Elasticsearch
CMD ["elasticsearch"]