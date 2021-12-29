####################################################################################################
## Builder
####################################################################################################
FROM rust:1.57-slim-buster AS builder

RUN apt-get update && apt-get upgrade -y && apt-get install -y pkg-config libssl-dev ca-certificates
RUN update-ca-certificates

# Create appuser
ENV USER=raccoon-detector
ENV USER_GROUP=$USER
ENV UID=1001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

WORKDIR /raccoon-detector

COPY ./ .

RUN cargo build --release

####################################################################################################
## Final image
####################################################################################################
FROM debian:buster-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y libssl-dev ca-certificates
RUN update-ca-certificates

# Import from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

WORKDIR /raccoon-detector

# Copy our build
COPY --from=builder /raccoon-detector/target/release/raccoon-detector ./

# Use an unprivileged user.
USER $USER_GROUP:$USER

CMD ["/raccoon-detector/raccoon-detector"]