# coding: utf-8
#--------------------------------------------------------------
# detectMagnetic_v2.rb
# $sudo ruby detectMagnetic_v2.rb
# Last update: 2016/12/14
# Author: Sho KANEMARU
#--------------------------------------------------------------
$LOAD_PATH.push('.')
require 'json'
require 'net/http'
require 'uri'
require 'base64'
require 'pi_piper'
require 'yaml'
#----------------- 設定ファイル読み込み ------------
confFileName = "./config.yml"
config = YAML.load_file(confFileName)

# デバイスID (Cumulocityが払い出したID)
DEVICEID = config["deviceId"]
# CumulocityへのログインID
USERID = config["userId"]
# Cumulocityへのログインパスワード
PASSWD = config["password"]
# GPIOのPIN番号
GPIO_PIN = config["gpioPin"]
# CumulocityのURL
URL = config["url"] + "/measurement/measurements/"
#----------------------- 以降、編集不可 --------------------------

puts DEVICEID
puts USERID
puts URL
puts GPIO_PIN

# 読み込むGPIOのPINを指定
pin = PiPiper::Pin.new(:pin => GPIO_PIN, :direction => :in, :pull => :down)

loop do
  # 測定日時を取得する
  day = Time.now
  time = day.strftime("%Y-%m-%dT%H:%M:%S.000+09:00")
  puts time

  # GPIOの値(0または1)を読む
  pin.read

  # Cumulocityへ送付するデータ(JSON形式)を設定する
  data_magnetic = {
    :MagneticMeasurement => {
      :T => {
        :value => pin.value,
        :unit => "C"
      }
    },
    :time => time,
    :source => {
      :id => DEVICEID
    },
    :type => "Magnetic_Measurement"
  }
  
  # magneticセンサーの値を画面に表示
  puts "******************************"
  puts "value: #{pin.value}"
  puts "******************************"
  
  # URLからURI部分を抽出(パース処理)
  uri = URI.parse(URL)

  # 以降、HTTP送信処理
  https = Net::HTTP.new(uri.host, uri.port)
  #https.set_debug_output $stderr
  https.use_ssl = true # HTTPSを使用
  
  # httpリクエストヘッダの設定
  initheader = {
    'Content-Type' =>'application/vnd.com.nsn.cumulocity.measurement+json; charset=UTF-8; ver=0.9',
    'Accept'=>'application/vnd.com.nsn.cumulocity.measurement+json; charset=UTF-8; ver=0.9',
    'Authorization'=>'Basic ' + Base64.encode64(USERID + ":" + PASSWD)
  }
  
  # httpリクエストの生成、送信
  request = Net::HTTP::Post.new(uri.request_uri, initheader)
  payload = JSON.pretty_generate(data_magnetic)
  request.body = payload
  #p request
  response = https.request(request)
  
  # API実行結果を画面に表示
  puts "------------------------"
  puts "code -> #{response.code}"
  #puts "msg -> #{response.message}"
  #puts "body -> #{response.body}"
  
  sleep 1
end

uexp = open("/sys/class/gpio/unexport", "w")
uexp.write(18)
uexp.close


