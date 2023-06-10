#!/bin/bash
# based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
# initial data; they need to be filled by the user
## API token
api_token=<Use your own API token>
## email address associated with the Cloudflare account (seems to be optional)
email=<Your own email>
## the zone (domain) should be modified ex. mydomain.com
zone_name=<your domain>
## the dns record (sub-domain) should be modified ex. myhost.mydomain.com
dns_record=<yourhost.your domain


# Proxy - uncomment and provide details if using a proxy
#export https_proxy=http://<proxyuser>:<proxypassword>@<proxyip>:<proxyport>


# get the basic data
ipv4=$(curl -s -X GET -4 https://ifconfig.co)
ipv6=$(curl -s -X GET -6 https://ifconfig.co)
user_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
               -H "Authorization: Bearer $api_token" \
               -H "Content-Type:application/json" \
          | jq -r '{"result"}[] | .id'
         )

echo "Your IPv4 is: $ipv4"
echo "Your IPv6 is: $ipv6"

# check if the user API is valid and the email is correct
if [ $user_id ]
then
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name&status=active" \
                   -H "Content-Type: application/json" \
                   -H "X-Auth-Email: $email" \
                   -H "Authorization: Bearer $api_token" \
              | jq -r '{"result"}[] | .[0] | .id'
             )
    # check if the zone ID is 
    if [ $zone_id ]
    then
        # check if there is any IP version 4
        if [ $ipv4 ]
        then
            dns_record_a_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$dns_record"  \
                                   -H "Content-Type: application/json" \
                                   -H "X-Auth-Email: $email" \
                                   -H "Authorization: Bearer $api_token"
                             )
            # if the IPv6 exist
            dns_record_a_ip=$(echo $dns_record_a_id |  jq -r '{"result"}[] | .[0] | .content')
            echo "The new IPv4 on Cloudflare (A Record) is:    $dns_record_a_ip"
            if [ $dns_record_a_ip != $ipv4 ]
            then
                # change the A record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_a_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
            else
                echo "The current IPv4 and DNS record IPv4 are the same."
            fi
            echo "DNS update may take 30 seconds or more"
            echo "Verifying new IPv4 address via dig at cloudflare: " `dig @carla.ns.cloudflare.com A $dns_record +short`
        else
            echo "Could not get your IPv4. Check if you have it; e.g. on https://ifconfig.co"
        fi
            
        # check if there is any IP version 6
        if [ $ipv6 ]
        then
            dns_record_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$dns_record"  \
                                      -H "Content-Type: application/json" \
                                      -H "X-Auth-Email: $email" \
                                      -H "Authorization: Bearer $api_token"
                                )
            # if the IPv6 exist
            dns_record_aaaa_ip=$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .content')
            echo "The new IPv6 on Cloudflare (AAAA Record) is: $dns_record_aaaa_ip"
            if [ $dns_record_aaaa_ip != $ipv6 ]
            then
                # change the AAAA record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"AAAA\",\"name\":\"$dns_record\",\"content\":\"$ipv6\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
            else
                echo "The current IPv6 and DNS record IPv6 are the same."
            fi
            echo "DNS update may take 30 seconds or more"
            echo "Verifying new IPv6 address via dig at cloudflare: " `dig @carla.ns.cloudflare.com AAAA $dns_record +short`
        else
            echo "Could not get your IPv6. Check if you have it; e.g. on https://ifconfig.co"
        fi  
    else
        echo "There is a problem with getting the Zone ID. Check if the Zone Name is correct."
    fi
else
    echo "There is a problem with either the email or the password"
fi
