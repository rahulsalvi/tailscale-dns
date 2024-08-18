FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/wolfi-base AS build
RUN apk update && apk add build-base git libcap-utils openssh go-1.23

WORKDIR /work

COPY go.mod go.sum main.go .
ARG TARGETOS TARGETARCH
RUN GOOS=${TARGETOS} GOARCH="${TARGETARCH}" CGO_ENABLED=0 go build -v -o coredns .
RUN setcap cap_net_bind_service=+ep coredns

FROM cgr.dev/chainguard/static:latest

COPY --from=build /work/coredns /coredns
COPY ./Corefile /Corefile

ENTRYPOINT ["/coredns"]
CMD []
