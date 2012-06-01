module GoogleApps
	module Atom
  	class User
      attr_reader :document
      
  		def initialize
        new_doc
  			add_header
  		end

      # new_user adds the nodes necessary to create a new
      # user in Google Apps.  new_user requires a username,
      # first name, last name and password.  You can also
      # provide an optional quota argument, this will override
      # the default quota in Google Apps.
      #
      # new_user 'username', 'first_name', 'last_name', 'password', 1024
      #
      # new_user returns the full XML document.
  		def new_user(user_name, first, last, password, quota=nil)
        set_values suspended: 'false', username: user_name, password: password, first_name: first, last_name: last, quota: quota
  		end

      # TODO: Document
      def set_values(values = {})
        @document.root << login_node(values[:suspended], values[:username], values[:password])
        @document.root << quota_node(values[:quota]) if values[:quota]
        @document.root << name_node(values[:first_name], values[:last_name]) if values[:first_name] and values[:last_name]

        @document
      end

      # login_node adds an apps:login attribute to @document.
      #  login_node takes a username and password as arguments
      # it is also possible to specify that the account be 
      # suspended.
      #
      # login_node 'username', 'password', suspended
      #
      # login_node returns an 'apps:login' LibXML::XML::Node
  		def old_login_node(user_name, password, suspended="false")
        suspended = "true" unless suspended == "false"
  			login = Atom::XML::Node.new('apps:login')
  			login['userName'] = user_name
  			login['password'] = OpenSSL::Digest::SHA1.hexdigest password
  			login['hashFunctionName'] = Atom::HASH_FUNCTION
  			login['suspended'] = suspended

  			login
  		end

      # TODO: This needs to be cleaned and documented.
      def login_node(suspended = "false", user_name = nil, password = nil)
        login = Atom::XML::Node.new('apps:login')
        login['userName'] = user_name unless user_name.nil?
        login['password'] = OpenSSL::Digest::SHA1.hexdigest password unless password.nil?
        login['hashFunctionName'] = Atom::HASH_FUNCTION unless password.nil?
        login['suspended'] = suspended.to_s

        login
      end


      # quota_node adds an apps:quota attribute to @document.  
      # quota_node takes an integer value as an argument.  This
      # argument translates to the number of megabytes available
      # on the Google side.
      #
      # quota_node 1024
      #
      # quota_node returns an 'apps:quota' LibXML::XML::Node
  		def quota_node(limit)
  			quota = Atom::XML::Node.new('apps:quota')
  			quota['limit'] = limit.to_s

  			quota
  		end

      # name_node adds an apps:name attribute to @document.  
      # name_node takes the first and last names as arguments.
      #
      # name_node 'first name', 'last name'
      #
      # name_node returns an apps:name LibXML::XML::Node
  		def name_node(first, last)
  			name = Atom::XML::Node.new('apps:name')
  			name['familyName'] = last
  			name['givenName'] = first

  			name
  		end

      # to_s returns @document as a string
      def to_s
        @document.to_s
      end

      private

      # new_doc re-initializes the XML document.
      def new_doc
        @document = Atom::XML::Document.new
      end

      def add_header
        @document.root = Atom::XML::Node.new('atom:entry')

        Atom::XML::Namespace.new(@document.root, 'atom', 'http://www.w3.org/2005/Atom')
        Atom::XML::Namespace.new(@document.root, 'apps', 'http://schemas.google.com/apps/2006')

        category = Atom::XML::Node.new('atom:category')
        category.attributes['scheme'] = 'http://schemas.google.com/g/2005#kind'
        category.attributes['term'] = 'http://schemas.google.com/apps/2006#user'

        @document.root << category
      end
  	end
  end
end