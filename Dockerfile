FROM ghcr.io/umami-software/umami:postgresql-latest
USER root
RUN apk update
RUN apk add --no-cache postgresql postgresql-contrib

COPY start-umami.sh /start-umami.sh
RUN chmod +x /start-umami.sh

ENV POSTGRES_USER=umami
ENV POSTGRES_PASSWORD=umami
ENV POSTGRES_DB=umami
ENV DATABASE_URL=postgresql://umami:umami@0.0.0.0:5432/umami

CMD ["sh", "/start-umami.sh"]
