require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'basic meetbot',  :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def puppet_manifest
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(puppet_manifest, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(puppet_manifest, catch_changes: true)
  end

  describe command(" curl http://localhost") do
    its(:stdout) { should contain('Welcome to Openstack IRC log server') }
  end

  expected_vhost = <<EOF
# ************************************
# Managed by Puppet
# ************************************

NameVirtualHost *:80
<VirtualHost *:80>
  ServerName eavesdrop.openstack.org
  DocumentRoot /srv/meetbot-openstack
  <FilesMatch \.log$>
    ForceType text/plain
    AddDefaultCharset UTF-8
  </FilesMatch>
  <Directory /srv/meetbot-openstack>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Order allow,deny
    allow from all
    <IfVersion >= 2.4>
      Require all granted
    </IfVersion>
  </Directory>


  <Location /alert>
    Header set Access-Control-Allow-Origin "*"
  </Location>


  ErrorLog /var/log/apache2/eavesdrop.openstack.org_error.log
  LogLevel warn
  CustomLog /var/log/apache2/eavesdrop.openstack.org_access.log combined
  ServerSignature Off
</VirtualHost>
EOF
  describe file('/etc/apache2/sites-enabled/50-eavesdrop.openstack.org.conf') do
    its(:content) { should eq expected_vhost }
  end
end
