package HTTPDModules;
%modules = (
    'access' => {
                    summary   => 'Provides access control based on client host name, IP address, etc.',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'actions' => {
                    summary   => 'Executing CGI scripts based on media type or request method',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'alias' => {
                    summary   => 'Mapping different parts of the host file system in the document tree and for URL redirection',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'auth' => {
                    summary   => 'User authentication using text files',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'auth_dbm' => {
                    summary   => 'Provides for user authentication using DBM files',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'autoindex' => {
                    summary   => 'Generates directory indices, automatically, similar to the Unix ls command',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    cgi => {
                    summary   => 'Execution of CGI scripts',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    dir => {
                    summary   => 'Provides for "trailing slash" redirects and serving directory index files',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    env => {
                    summary   => 'Modifies the environment passed to CGI scripts and SSI pages',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    expires => {
                    summary   => 'Generation of Expires HTTP headers according to user-specified criteria',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    include => {
                    summary   => 'Server-parsed HTML documents (Server Side Includes)',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'log_config' => {
                    summary   => 'Logging of the requests made to the server',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'mime' => {
                    summary   => 'Associates the requested file name\'s extensions with the file\'s behavior and content',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'negotiation' => {
                    summary   => 'Provides for content negotiation',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'setenvif' => {
                    summary   => 'Allows the setting of environment variables based on characteristics of the request',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'status' => {
                    summary   => 'Provides information about server activity and performance',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'suexec' => {
                    summary   => 'Allows CGI scripts to run as a specified user and group',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'userdir' => {
                    summary   => 'User-specific directories',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'asis' => {
                    summary   => 'Sends files that contain their own HTTP headers',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'auth_anon' => {
                    summary   => 'Allows "anonymous" user access to authenticated areas',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'auth_digest' => {
                    summary   => 'User authentication using MD5 Digest Authentication',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'auth_ldap' => {
                    summary   => 'Allows an LDAP directory to be used to store the database for HTTP Basic authentication',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'cache' => {
                    summary   => 'Content cache keyed to URIs',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'charset_lite' => {
                    summary   => 'Specify character set translation or recoding',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'dav' => {
                    summary   => 'Distributed Authoring and Versioning (WebDAV) functionality',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'dav_fs' => {
                    summary   => 'File system provider for mod_dav',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'deflate' => {
                    summary   => 'Compress content before it is delivered to the client',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'disk_cache' => {
                    summary   => 'Content cache storage manager keyed to URIs',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'echo' => {
                    summary   => 'A simple echo server to illustrate protocol modules',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'ext_filter' => {
                    summary   => 'Pass the response body through an external program before delivery to the client',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'file_cache' => {
                    summary   => 'Caches a static list of files in memory',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'headers' => {
                    summary   => 'Customization of HTTP request and response headers',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'imap' => {
                    summary   => 'Server-side image map processing',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'info' => {
                    summary   => 'Provides a comprehensive overview of the server configuration',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'ldap' => {
                    summary   => 'LDAP connection pooling and result caching services for use by other LDAP modules',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'logio' => {
                    summary   => 'Logging of input and output bytes per request',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'mem_cache' => {
                    summary   => 'Content cache keyed to URIs',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'mime_magic' => {
                    summary   => 'Determines the MIME type of a file by looking at a few bytes of its contents',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'proxy' => {
                    summary   => 'HTTP/1.1 proxy/gateway server',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'proxy_connect' => {
                    summary   => 'mod_proxy extension for CONNECT request handling',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'proxy_ftp' => {
                    summary   => 'FTP support module for mod_proxy',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'proxy_http' => {
                    summary   => 'HTTP support module for mod_proxy',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'rewrite' => {
                    summary   => 'Provides a rule-based rewriting engine to rewrite requested URLs on the fly',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'speling' => {
                    summary   => 'Attempts to correct mistaken URLs that users might have entered',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'ssl' => {
                    summary   => 'Strong cryptography using the Secure Sockets Layer (SSL) and Transport Layer Security (TLS) protocols',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'unique_id' => {
                    summary   => 'Provides an environment variable with a unique identifier for each request',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'usertrack' => {
                    summary   => 'Clickstream logging of user activity on a site',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'vhost_alias' => {
                    summary   => 'Provides support for dynamically configured mass virtual hosting',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'php4' => {
                    summary   => 'Provides support for PHP4 dynamically generated pages',
                    packages  => ["apache2-mod_php4"],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'perl' => {
                    summary   => 'Provides support for Perl dynamically generated pages',
                    packages  => ["apache2-mod_perl"],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'python' => {
                    summary   => 'Provides support for Python dynamically generated pages',
                    packages  => ["apache2-mod_python"],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    },
    'ruby' => {
                    summary   => 'Provides support for Ruby dynamically generated pages',
                    packages  => ["apache2-mod_ruby"],
                    default   => 1,
                    required  => 0,
                    suggested => 0
    }
);


%selection = (
    TestSel => {
                summary => 'A test selection',
                modules => [ "perl", "php4", "ruby" ],
                default => 0
    }
);

