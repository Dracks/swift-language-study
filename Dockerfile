FROM swift:5.9 AS base

FROM base AS build

COPY . ./

RUN ls -la
RUN swift build -v
# RUN swift build -c release