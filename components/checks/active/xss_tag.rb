=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# XSS in HTML tag.
# It injects a string and checks if it appears inside any HTML tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.7
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XssTag < Arachni::Check::Base

    TAG_NAME = 'arachni_xss_in_tag'

    def self.strings
        @strings ||= [ " #{TAG_NAME}=" + random_seed, "\" #{TAG_NAME}=\"" + random_seed,
                       "' #{TAG_NAME}='" + random_seed ]
    end

    def run
        audit( self.class.strings, format: [ Format::APPEND ] ) do |response, element|
            check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        body = response.body.downcase

        # if we have no body or it doesn't contain the TAG_NAME under any
        # context there's no point in parsing the HTML to verify the vulnerability
        return if !body.include?( TAG_NAME )

        # see if we managed to inject a working HTML attribute to any
        # elements
        Nokogiri::HTML( body ).xpath( "//*[@#{TAG_NAME}]" ).each do |node|
            next if node[TAG_NAME] != random_seed

            proof = (payload = find_included_payload( body )) ? payload : node.to_s
            log vector: element, proof: proof, response: response
        end
    end

    def find_included_payload( body )
        self.class.strings.each do |payload|
            return payload if body.include?( payload )
        end
        nil
    end

    def self.info
        {
            name:        'XSS in HTML tag',
            description: %q{Cross-Site Scripting in HTML tag.},
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.7',

            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in HTML tag},
                description:     %q{
Client-side scripts are used extensively by modern web applications.
They perform both simple functions (such as the formatting of text) up to full
manipulation of client side data and operating system interaction.

Cross Site Scripting (XSS) allows clients to inject scripts into a request and
have the server return the script to the client. This occurs because the
application is taking untrusted data (in this example from the client) and reusing
it without performing any validation or sanitisation.

If the injected script is returned immediately this is known as reflected XSS.
If the injected script is stored by the server and returned to any client visiting
the affected page then this is known as persistent XSS (also stored XSS).

A common attack used by cyber-criminals is to steal a client's session token by
injecting JavaScript, however, XSS vulnerabilities can also be abused to exploit
clients, for example, by visiting the page either directly or through a crafted
HTTP link delivered via a social engineering email.

Arachni has discovered that it is possible to insert content directly into a HTML
tag. For example `<INJECTION_HERE href=.......etc>` where `INJECTION_HERE`
represents the location where the Arachni payload was detected.
},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/',
                    'WASC' => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting'
                },

                tags:            %w(xss script tag regexp dom attribute injection),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
To remedy XSS vulnerabilities, it is important to never use untrusted or unfiltered
data within the code of a HTML page.

Untrusted data can originate not only form the client but potentially a third
party or previously uploaded file etc.

Filtering of untrusted data typically involves converting special characters to
their HTML entity encoding equivalent (however, other methods do exist, see references).
These special characters include:

* `&`
* `<`
* `>`
* `"`
* `'`
* `/`

An example of HTML entity encoding is converting a `<` to `&lt;`.

Although it is possible to filter untrusted input, there are five locations
within a HTML page where untrusted input (even if it has been filtered) should
never be placed:

1. Directly in a script.
2. Inside an HTML comment.
3. In an attribute name.
4. In a tag name.
5. Directly in CSS.

Each of these locations have their own form of escaping and filtering.

_Because many browsers attempt to implement XSS protection, any manual verification
of this finding should be conducted utilising multiple different browsers and
browser versions._
}
            }
        }
    end

end
