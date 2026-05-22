FROM debian:stable-slim

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
      ca-certificates \
      fish \
      git \
    && rm -rf /var/lib/apt/lists/*

CMD ["fish", "-c", "git clone https://github.com/nickbutler/dots.git ~/.config/dotfiles && fish ~/.config/dotfiles/bin/dots; exec fish"]
