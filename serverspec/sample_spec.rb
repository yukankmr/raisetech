require 'spec_helper'

listen_port = 80
db_user = ENV['DB_USER']
db_password = ENV['DB_PASSWORD']
db_host = ENV['DB_HOST']
db_name = ENV['DB_NAME']
ec2_host = ENV['EC2_HOST']

# Test NGINX
# ・必要なパッケージがインストールされていること
# ・nginxの設定ファイルが正しい場所に存在していること
# ・nginxのプロセスが稼働していること
# ・nginxの自動起動設定がされていること
describe package('nginx') do
  it { should be_installed }
end

describe service('nginx') do
  it { should be_enabled }
  it { should be_running }
end

describe port(listen_port) do
  it { should be_listening }
end

describe file('/etc/nginx/conf.d/rails.conf') do
  it { should exist }
end

describe file('/etc/nginx/conf.d/rails.conf') do
  its(:content) { should match /server_name #{ec2_host}/ }
end

# Test MySQL
# ・DBが作られていること
describe command("mysqlshow -u #{db_user} -h #{db_host} -p#{db_password} #{db_name}" ) do
    its(:stdout) { should contain("#{db_name}").from("Database:") }
end

# Test Application
# ・必要なパッケージがインストールされていること
# ・pumaプロセスが稼働していること
# ・ALBのDNSのAレコードからアプリへアクセスしてステータスコード200で返ってくること
%w(python3 gcc-c++ make python3-pip git openssl-devel readline-devel zlib-devel).each do |pkg|
  describe package(pkg) do
    it { should be_installed }
  end
end

describe command('ruby -v') do
  let(:sudo_options) { '-u ec2-user -i' }
  its(:stdout) { should match /ruby 2\.6\.3p62/ }
end

describe package('rails') do
  let(:sudo_options) { '-u ec2-user -i' }
  it { should be_installed.by('gem').with_version('6.0.4.8') }
end

describe command('ps axu | grep puma | grep -v grep') do
  its(:exit_status) { should eq 0 }
end

describe command('curl http://example.elb.amazonaws.com/ -sIo /dev/null -w "%{http_code}\n"') do
  its(:stdout) { should match /^200$/ }
end
