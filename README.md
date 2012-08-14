# Google Apps API

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/LeakyBucket/google_apps)

## What is this?

This is another GoogleApps API Library.  I know there is one floating around out there but it is 2 years old and doesn't claim to do more than: users, groups, and calendar.

The goal here is a library that supports the entire GoogleApps Domain and Applications APIs.

#### Currently Supported:

__Domain API__

  * Authentication
  * Provisioning
    * Users
      * User Creation
      * User Deletion
      * User Record Retrieval
      * User Modification
      * Retrieve all users in the domain
    * Groups
      * Group Creation
      * Group Deletion
      * Group Record Retrieval
      * Add Group Member
      * Delete Group Member
      * Modify Group Attributes
      * Member List
    * Nicknames
      * Creation
      * Deletion
      * List Nicknames for a User
  * Public Key Upload
  * Email Audit
    * Mailbox Export Request
    * Mailbox Export Status Check
    * Mailbox Export Download
  * Email Migration
    * Message Upload
    * Set Message Attributes


#### TODO:

__Domain__

  * Admin Audit
  * Admin Settings
  * Calendar Resource
  * Domain Shared Contacts
  * Email Audit
    * Email Monitors
    * Account Information
  * Email Settings
  * Reporting
  * Reporting Visualization
  * User Profiles

__Application__

  * Calendar Data
  * Contacts Data
  * Documents List Data
  * Sites Data
  * Spreadsheets Data
  * Tasks

## Short How

Getting and using the library.  

~~~~~
gem install google_apps

require 'google_apps'
~~~~~


Setting up your GoogleApps::Transport object to send requests to Google.  

~~~~~
transporter = GoogleApps::Transport.new 'domain'
transporter.authenticate 'username@domain', 'password'
~~~~~


Creating an entity is a matter of creating a matching object and sending it to Google.  

~~~~~
# Creating a User
user = GoogleApps::Atom::User.new
user = GoogleApps::Atom::User.new <xml string>

# or

user = GoogleApps::Atom.user
user = GoogleApps::Atom.user <xml string>


user.set login: 'JWilkens', password: 'uncle J', first_name: 'Johnsen', last_name: 'Wilkens'

# or

user.login = 'JWilkens'
user.password = 'uncle J'
user.first_name = 'Johnsen'
user.last_name = 'Wilkens'

transporter.new_user user
~~~~~


Modifying an entity is also a simple process.  

~~~~~
# Modifying a User
user.last_name = 'Johnson'
user.suspended = true

transporter.update_user 'bob', user
~~~~~


Deleting is extremely light weight.  

~~~~~
transporter.delete_user 'bob'
~~~~~


Getting an entity record from Google.  

~~~~~
# Retrieving a User
transporter.get_user 'bob'
~~~~~


Retrieving a batch of entities from Google.  

~~~~~
# Retrieving all Users
transporter.get_users

transporter.feeds.each do |feed|
  feed.items.each do |user|
    puts user.login
  end
end


# Retrieving a range of Users
transporter.get_users start: 'lholcomb2', limit: 320

transporter.feeds.each do |feed|
  feed.items.each do |user|
    puts user.login
  end
end
~~~~~


Google Apps uses public key encryption for mailbox exports and other audit functionality.  Adding a key is fairly simple.  

~~~~~
# Uploading Public Key
pub_key = GoogleApps::Atom::PublicKey.new
pub_key.new_key File.read('key_file')

transporter.add_pubkey pub_key
~~~~~


Google Apps provides a few mail auditing functions.  One of those is grabbing a mailbox export.  Below is an example.  

~~~~~
# Request Mailbox Export
export_req = GoogleApps::Atom::Export.new
export_req.query 'from:Bob'
export_req.content 'HEADER_ONLY'

transporter.request_export 'username', export_req
~~~~~


Your export request will be placed in a queue and processed eventually.  Luckily you can check on the status while you wait.  

~~~~~
# Check Export Status
transporter.export_status 'username', <request_id>
transporter.export_ready? 'username', <request_id>
~~~~~


Downloading the requested export is simple.  

~~~~~
# Download Export
transporter.fetch_export 'username', 'req_id', 'filename'
~~~~~


The Google Apps API provides a direct migration option if you happen to have email in msg (RFC 822) format.  

~~~~~
# Migrate Email
attributes = GoogleApps::Atom::MessageAttributes.new
attributes.add_label 'Migration'

transporter.migrate 'username', attributes, File.read(<message>)
~~~~~

## Long How

#### GoogleApps::Transport

This is the main piece of the library.  The Transport class does all the heavy lifting and communication between your code and the Google Apps Envrionment.

Transport will accept a plethora of configuration options.  However most have currently sane defaults.  In particular the endpoint values should default to currently valid URIs.

The only required option is the name of your domain:

~~~~
GoogleApps::Transport.new 'cnm.edu'
~~~~

This domain value is used to set many of the defaults, which are:

  * @auth - The default base URI for auth requests (This will change once OAuth support is added).
  * @user - The default base URI for user related API requests.
  * @pubkey - The default base URI for public key related API requests.
  * @migration - The default base URI for email migration related API requests.
  * @group - The default base URI for group related API requests.
  * @nickname - The default base URI for nickname related API requests.
  * @export - The default base URI for mail export related API requests.
  * @requester - The class to use for making API requests, the default is GoogleApps::AppsRequest
  * @doc_handler - The doc_handler parses Google Apps responses and returns the proper document object.  The default format is :atom, you can specify a different format by passing format: <format> during Transport instantiation.

GoogleApps::Transport is your interface for any HTTP verb related action.  It handles GET, PUT, POST and DELETE requests.  Transport also provides methods for checking the status of long running requests and downloading content.


### GoogleApps::Atom::User

This class represents a user record in the Google Apps Environment.  It is basically a glorified LibXML::XML::Document.

~~~~
user = GoogleApps::Atom::User.new
user = GoogleApps::Atom::User.new <xml string>

# or

user = GoogleApps::Atom.user
user = GoogleApps::Atom.user <xml string>
~~~~

User provides a basic accessor interface for common attributes.

~~~~
user.login = 'lholcomb2'
# password= will return the plaintext password string but will set a SHA1 encrypted password.
user.password = 'hobobob'
user.first_name = 'Glen'
user.last_name = 'Holcomb'
user.suspended = false
user.quota = 1000


user.login
> 'lholcomb2'

# password returns the SHA1 hash of the password
user.password
> 'b8b32c3e5233b4891ae47bd31e36dc472987a7f4'

user.first_name
> 'Glen'

user.last_name
> 'Holcomb'

user.suspended
> false

user.quota
> 1000
~~~~

It also provides methods for setting and updating less common nodes and attributes.

~~~~
user.update_node 'apps:login', :agreedToTerms, true

# if the user specification were to change or expand you could manually set nodes in the following way.
user.add_node 'apps:property', [['locale', 'Spanish']]
~~~~

GoogleApps::Atom::User also has a to_s method that will return the underlying LibXML::XML::Document as a string.


### GoogleApps::Atom::Group

This class represents a Google Apps Group.  Similarly to GoogleApps::Atom::User this is basically a LibXML::XML::Document.

~~~~
group = GoogleApps::Atom::Group.new
group = GoogleApps::Atom::Group.new <xml string>

# or

group = GoogleApps::Atom.group
group = GoogleApps::Atom.group <xml string>
~~~~

The Group class provides getters and setter for the standard group properties.

~~~~
group.id = 'Group ID'
group.name = 'Example Group'
group.permissions = 'Domain'
group.description = 'A Simple Example'

group.id
> 'Group ID'
group.name
> 'Example Group'
group.permissions
> 'Domain'
group.description
> 'A Simple Example'
~~~~

*Note:*  Group Membership is actually handled separately in the Google Apps Environment, therefore it is handled separately in this library as well (for now at least). See the next section for Group Membership.


### GoogleApps::Atom::GroupMember

This class is representative of a Google Apps Group Member.

~~~~
member = GoogleApps::Atom::GroupMember.new
member = GoogleApps::Atom::GroupMember.new <xml string>

# or

member = GoogleApps::Atom.group_member
member = GoogleApps::Atom.gorup_member <xml string>
~~~~

A GroupMember really only has one attribute.  The id of the member.

~~~~
member.member = 'bogus_account@cnme.edu'

member.member
> 'bogus_account@cme.edu'
~~~~

To add a group member you need to make an add_member_to request of your GoogleApps::Transport object.  The method requires the id of the group the member is being added to as well as the member doucument.

~~~~
transporter.add_member_to 'Group ID', member
~~~~

Id's are unique within the Google Apps environment so it is possible to add a group to another group.  You just need to supply the group id as the member value for the GoogleApps::Atom::GroupMember object.


### GoogleApps::Atom::MessageAttributes


The MessageAttributes class represents a Google Apps Message Attribute XML Document.

~~~~
attributes = GoogleApps::Atom::MessageAttributes.new
attributes = GoogleApps::Atom::MessageAttributes.new <xml string>

# or

attributes = GoogleApps::Atom.message_attributes
attributes = GoogleApps::Atom.message_attributes <xml string>
~~~~

