FROM swift:5.9 AS base

FROM base AS build

ARG VERSION
ARG GIT_COMMIT

COPY ./Package.* ./
COPY swift-language-study swift-language-study
COPY swift-language-study-tests swift-language-study-tests
COPY .build .build

# RUN swift package resolve --skip-update --force-resolved-versions
RUN echo "struct BuildInfo { static let version = \"$VERSION\"; static let gitCommit = \"$GIT_COMMIT\" }" > swift-language-study/build-info.swift


RUN swift build -c release --static-swift-stdlib \
    # Workaround for https://github.com/apple/swift/pull/68669
    # This can be removed as soon as 5.9.1 is released, but is harmless if left in.
    -Xlinker -u -Xlinker _swift_backtrace_isThunkFunction

RUN cp "$(swift build -c release --show-bin-path)/App" ./app

FROM base AS runtime

RUN mkdir -p /home/vapor

WORKDIR /home/vapor/

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /home/vapor vapor && chown vapor:vapor /home/vapor

COPY --from=build --chown=vapor:vapor /app app

COPY --chown=vapor:vapor Public Public

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_ROOT=/usr SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no

# Ensure all further commands run as the vapor user
USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./app"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
