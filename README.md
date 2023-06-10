# cloudflare_ddns_update.sh

Prerequesites, get your API token to allow for read and writing to Cloudflare with the zone_name. For more information on how to create, see the Cloudflare documentation at: https://developers.cloudflare.com/fundamentals/api/get-started/create-token/

*Remember to safeguard your API token, do not post or share.*

This bash script works on Mac or other *nix systems. It will check your IPv4 and IPv6 against the registered dns_record in the domain zone_name in the Cloudflare DNS.

# initial data that needs to be filled in by the user
## API token
api_token= Use your own API token
## email address associated with the Cloudflare account (seems to be optional)
email= Your own email
## the zone (domain) should be modified ex. mydomain.com
zone_name= your domain
## the dns record (sub-domain) should be modified ex. myhost.mydomain.com
dns_record= yourhost.your domain

# Reference
Based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
