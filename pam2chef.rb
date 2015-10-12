#!/usr/bin/env ruby
require 'erb'

passwd_file = '/etc/passwd'


def get_user_data(line_array)
    username = line_array[0]
    password = line_array[1] 
    uid      = line_array[2] 
    gid      = line_array[3] 
    home     = line_array[5] 
    
    return [username, password, uid, gid, home]
end



def get_template()

    %{ 
    <%- username = user_data[0] -%>
    <%- password = user_data[1] -%>
    <%- uid      = user_data[2] -%>
    <%- gid      = user_data[3] -%>
    <%- home     = user_data[4] -%>
         {
           "id": "<%= username %>",
           "password": "<%= password %>",
           "ssh_keys": [
           ],
           "uid": <%= uid %>,
           "gid": <%= gid %>,
           "shell": "/sbin/nologin",
           "home": "<%= home %>",
           "comment": "Customer_Account"
         }
     }
end


class Pam2chef
    include ERB::Util
    attr_accessor :user_data, :template

    def initialize(user_data, template)
        @user_data = user_data
        @template  = template
    end

    def render
         #renderer = ERB.new(@template, 0, '>')       
         renderer = ERB.new(@template, 0, '-').result(binding)
    end

    def save(file)
        File.open(file, "w+") do |f|
            f.write(render)
        end
    end

    def print
        puts render
    end
end



begin
    passwd_file_a = []
    user_data   = []
    user_exclude_list = [ 'username1', 'serviceUser']
    
    File.readlines(passwd_file).each do |line|
        passwd_file_a << line
    end
    
    passwd_file_a.each do |line|
        line_array = line.split(':')

        next if line_array[2].to_i < 500
        next if user_exclude_list.include?(line_array[0])

        filename = line_array[0] + '.json'
        
        single_line = Pam2chef.new(get_user_data(line_array), get_template)
        single_line.save("users/#{filename}")
        #single_line.print # used for testing or to redirect to a single file
    end
end

