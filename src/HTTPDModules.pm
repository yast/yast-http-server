package YaPI::HTTPDModules;
%modules = (
    'access' => {
                    summary   => 'Provides access control based on client host name, IP address, etc.',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 10
    },
    'actions' => {
                    summary   => 'Executing CGI scripts based on media type or request method',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 20
    },
    'alias' => {
                    summary   => 'Mapping different parts of the host file system in the document tree and for URL redirection',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 30
    },
    'auth' => {
                    summary   => 'User authentication using text files',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 40
    },
    'auth_dbm' => {
                    summary   => 'Provides for user authentication using DBM files',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 50
    },
    'autoindex' => {
                    summary   => 'Generates directory indices, automatically, similar to the Unix ls command',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 60
    },
    'cgi' => {
                    summary   => 'Execution of CGI scripts',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 70
    },
    'dir' => {
                    summary   => 'Provides for "trailing slash" redirects and serving directory index files',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 80
    },
    'env' => {
                    summary   => 'Modifies the environment passed to CGI scripts and SSI pages',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 90
    },
    'expires' => {
                    summary   => 'Generation of Expires HTTP headers according to user-specified criteria',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 100
    },
    'include' => {
                    summary   => 'Server-parsed HTML documents (Server Side Includes)',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 110
    },
    'log_config' => {
                    summary   => 'Logging of the requests made to the server',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 120
    },
    'mime' => {
                    summary   => 'Associates the requested file name\'s extensions with the file\'s behavior and content',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 130
    },
    'negotiation' => {
                    summary   => 'Provides for content negotiation',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 140
    },
    'setenvif' => {
                    summary   => 'Allows the setting of environment variables based on characteristics of the request',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 150
    },
    'status' => {
                    summary   => 'Provides information about server activity and performance',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 160
    },
    'suexec' => {
                    summary   => 'Allows CGI scripts to run as a specified user and group',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 0
    },
    'userdir' => {
                    summary   => 'User-specific directories',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 180
    },
    'asis' => {
                    summary   => 'Sends files that contain their own HTTP headers',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 190
    },
    'auth_anon' => {
                    summary   => 'Allows "anonymous" user access to authenticated areas',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 200
    },
    'auth_digest' => {
                    summary   => 'User authentication using MD5 Digest Authentication',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 210
    },
    'auth_ldap' => {
                    summary   => 'Allows an LDAP directory to be used to store the database for HTTP Basic authentication',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 220
    },
    'cache' => {
                    summary   => 'Content cache keyed to URIs',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 230
    },
    'charset_lite' => {
                    summary   => 'Specify character set translation or recoding',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 240
    },
    'dav' => {
                    summary   => 'Distributed Authoring and Versioning (WebDAV) functionality',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 250
    },
    'dav_fs' => {
                    summary   => 'File system provider for mod_dav',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 260
    },
    'deflate' => {
                    summary   => 'Compress content before it is delivered to the client',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 270
    },
    'disk_cache' => {
                    summary   => 'Content cache storage manager keyed to URIs',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 280
    },
    'echo' => {
                    summary   => 'A simple echo server to illustrate protocol modules',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 290
    },
    'ext_filter' => {
                    summary   => 'Pass the response body through an external program before delivery to the client',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 300
    },
    'file_cache' => {
                    summary   => 'Caches a static list of files in memory',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 310
    },
    'headers' => {
                    summary   => 'Customization of HTTP request and response headers',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 320
    },
    'imap' => {
                    summary   => 'Server-side image map processing',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 330
    },
    'info' => {
                    summary   => 'Provides a comprehensive overview of the server configuration',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 340
    },
    'ldap' => {
                    summary   => 'LDAP connection pooling and result caching services for use by other LDAP modules',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 350
    },
    'logio' => {
                    summary   => 'Logging of input and output bytes per request',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 360
    },
    'mem_cache' => {
                    summary   => 'Content cache keyed to URIs',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 370
    },
    'mime_magic' => {
                    summary   => 'Determines the MIME type of a file by looking at a few bytes of its contents',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 380
    },
    'proxy' => {
                    summary   => 'HTTP/1.1 proxy/gateway server',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 390
    },
    'proxy_connect' => {
                    summary   => 'mod_proxy extension for CONNECT request handling',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 400
    },
    'proxy_ftp' => {
                    summary   => 'FTP support module for mod_proxy',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 410
    },
    'proxy_http' => {
                    summary   => 'HTTP support module for mod_proxy',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 420
    },
    'rewrite' => {
                    summary   => 'Provides a rule-based rewriting engine to rewrite requested URLs on the fly',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 430
    },
    'speling' => {
                    summary   => 'Attempts to correct mistaken URLs that users might have entered',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 440
    },
    'ssl' => {
                    summary   => 'Strong cryptography using the Secure Sockets Layer (SSL) and Transport Layer Security (TLS) protocols',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 450
    },
    'unique_id' => {
                    summary   => 'Provides an environment variable with a unique identifier for each request',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 460
    },
    'usertrack' => {
                    summary   => 'Clickstream logging of user activity on a site',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 470
    },
    'vhost_alias' => {
                    summary   => 'Provides support for dynamically configured mass virtual hosting',
                    packages  => [],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 480
    },
    'php4' => {
                    summary   => 'Provides support for PHP4 dynamically generated pages',
                    packages  => ["apache2-mod_php4"],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 490
    },
    'perl' => {
                    summary   => 'Provides support for Perl dynamically generated pages',
                    packages  => ["apache2-mod_perl"],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 500
    },
    'python' => {
                    summary   => 'Provides support for Python dynamically generated pages',
                    packages  => ["apache2-mod_python"],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 510
    },
    'ruby' => {
                    summary   => 'Provides support for Ruby dynamically generated pages',
                    packages  => ["apache2-mod_ruby"],
                    default   => 1,
                    required  => 0,
                    suggested => 0,
                    position  => 520
    }
);


%selection = (
    TestSel => {
                summary => 'A test selection',
                modules => [ "m1", "m2", "m3" ],
                default => 0
    }
);

