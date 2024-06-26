# irc-url-title-bot
**irc-url-title-bot** is a dockerized Python 3.9 based IRC URL title posting bot.
It essentially posts the page titles of the URLs that are posted in the configured channels on an IRC server.
As a disclaimer, note that SSL verification is disabled, and that the posted titles are not guaranteed to be accurate
due to a number of factors.

## Links
| Caption   | Link                                                        |
|-----------|-------------------------------------------------------------|
| Code      | https://github.com/impredicative/irc-url-title-bot          |
| Changelog | https://github.com/impredicative/irc-url-title-bot/releases |
| Image     | https://hub.docker.com/r/ascensive/irc-url-title-bot        |

## Examples
```text
<Adam> For the mathematics of deep learning, see https://arxiv.org/abs/2105.04026 and https://arxiv.org/pdf/2104.14033
<TitleBot> ⤷ [2105.04026] The Modern Mathematics of Deep Learning | PDF: https://arxiv.org/pdf/2105.04026
<TitleBot> ⤷ [2104.14033] A Study of the Mathematics of Deep Learning | Abstract: https://arxiv.org/abs/2104.14033
<Eve> Is github.com/visinf/n3net a good project? I've been studying bugs.python.org/file47781/Tutorial_EDIT.pdf
<TitleBot> ⤷ GitHub - visinf/n3net: Neural Nearest Neighbors Networks (NIPS*2018)
<TitleBot> ⤷ Python Tutorial
```
For more examples, see [`urltitle`](https://github.com/impredicative/urltitle/).

## Usage
The bot can work in multiple channels but on only one server.
To use with multiple servers, use an instance per server.

### Configuration
Prepare a private `secrets.env` environment file using the sample below.
```ini
IRC_PASSWORD=YourActualPassword
```

Prepare a version-controlled `config.yaml` file using the sample below.
A full-fledged real-world example is also
[available](https://github.com/impredicative/irc-bots/blob/master/libera/title-bot/config.yaml).
```yaml
# Mandatory:
host: irc.libera.chat
port: 6697
ssl: true
nick: MyTitleBot
channels:
  - '#some_chan1'
  - '##some_chan2 somekey'

# Optional:
blacklist:
  title:
    - Invalid host
    - Untitled
  url:
    - model.fit
    - tf.app
ignores:
  - some_user1
  - some_user2
mode:

# Site-specific (optional):
sites:
  arxiv.org:
    format:
      - re:
          url: /pdf/(?P<url_id>.+?)(?:\.pdf)*$
        str:
          title: '{title} | https://arxiv.org/abs/{url_id}'
      - re:
          url: /abs/(?P<url_id>.+?)$
        str:
          title: '{title} | https://arxiv.org/pdf/{url_id}'
  bpaste.net:
    blacklist:
      title: show at bpaste
  imgur.com:
    blacklist:
      title: 'Imgur: The magic of the Internet'
  paste.ee:
    blacklist:
      title_re: ^Paste\.ee\ \-\ View\ paste\b
  youtube.com:
    blacklist:
      channels:
        - '##some_chan2'
```

#### Global settings

##### Mandatory
* **`host`**
* **`port`**
* **`nick`**
* **`channels`**

##### Optional
* **`blacklist.title`**: This is a list of strings. If a title is one of these strings, it is not posted.
The comparison is case insensitive.
* **`blacklist.url`**: This is a list of strings. If a URL is one of these strings, its title is not posted.
The comparison is case insensitive.
* **`ignores`**: This is a list of nicks to ignore.
* **`mode`**: This can for example be `+igR` for [Libera](https://libera.chat/guides/usermodes).
Setting it is recommended.

#### Site-specific settings
The site of a URL is as defined and returned by the
[`urltitle`](https://github.com/impredicative/urltitle/) package. Refer to the examples contained in the
[Customizations](https://github.com/impredicative/urltitle/#customizations) section of its readme.

Site-specific settings are specified under the top-level `sites` key.
The order of execution of the interacting operations is: `blacklist`, `format`.
Refer to the sample configuration for usage examples.

* **`alert.read`**: If `false`, a read failure is not alerted. The default is `true`.
* **`blacklist.channels`**: This is a list of channels for which a title is not posted if the URL matches the site.
The channel comparison is case insensitive.
* **`blacklist.title`**: This is a single string or a list of strings.
If the title for a URL matching the site is a blacklisted string, the title is not posted.
The comparison is case sensitive.
* **`blacklist.title_re`**: This is a single regular expression pattern that is
[searched](https://docs.python.org/3/library/re.html#re.search) for in the title.
If the title for a URL matching the site is matched against this blacklisted pattern, the title is not posted.
* **`format`**: This contains a list of entries, each of which have keys `re.title` and/or `re.url` along with
`str.title`.
* **`format.re.title`**: This is a single regular expression pattern that is
[searched](https://docs.python.org/3/library/re.html#re.search) for in the title.
It is used to collect named [key-value pairs](https://docs.python.org/3/library/re.html#re.Match.groupdict) from the
match.
If there isn't a match, the next entry in the parent list, if any, is attempted.
* **`format.re.url`**: This is similar to `format.re.title`.
If both this and `format.re.url` are specified, both patterns must then match their respective strings, failing which
the next entry in the parent list, if any, is attempted.
* **`format.str.title`**: The key-value pairs collected using `format.re.title` and/or `format.re.url`,
are combined along with the default additions of both `title` and `url` as keys.
The key-value pairs are used to [format](https://docs.python.org/3/library/stdtypes.html#str.format_map) the provided
quoted title string. The default value is `{title}`.
If the title is thereby altered, any remaining entries in the parent list are skipped.

### Deployment
* As a reminder, it is recommended that the alerts channel be registered and monitored.
* It is recommended that the bot be auto-voiced (+V) in each channel.

* It is recommended that the bot be run as a Docker container using using Docker ≥18.09.2, possibly with
Docker Compose ≥1.24.0.
To run the bot using Docker Compose, create or add to a version-controlled `docker-compose.yml` file:
```yaml
version: '3.7'
services:
  irc-url-title-bot:
    container_name: irc-url-title-bot
    image: ascensive/irc-url-title-bot:latest
    restart: always
    logging:
      options:
        max-size: 10m
        max-file: "3"
    volumes:
      - ./irc-url-title-bot:/config:ro
    env_file:
      - ./secrets.env
```

* In the above service definition in `docker-compose.yml`:
  * `image`: For better reproducibility, use a specific
  [versioned tag](https://hub.docker.com/r/ascensive/irc-url-title-bot/tags), e.g. `0.2.2` instead of `latest`.
  * `volumes`: Customize the relative path to the previously created `config.yaml` file, e.g. `./irc-url-title-bot`.
  * `env_file`: Customize the relative path to `secrets.env`.

* From the directory containing the above YAML file, run `docker-compose up -d irc-url-title-bot`.
Use `docker logs -f irc-url-title-bot` to see and follow informational logs.

### Maintenance
* If `config.yaml` is updated, the container must be restarted to use the updated file.
* If `secrets.env` or the service definition in `docker-compose.yml` are updated, the container must be recreated
(and not merely restarted) to use the updated file.
