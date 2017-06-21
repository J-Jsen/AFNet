# AFNet
可复制https://github.com/Sugar1413/AFNet.git 自行在自己终端上 clone 

需要coocapods集成AFNetworing ,在终端输入

pod search AFNetworking   找到集成的AFNet版本
cd 项目目录 
vim Podfile

platform :ios, '9.0'
target '工程名' do
pod 'AFNetworking', '~> 3.1.0'
end

esc --> :wq --> pod install
最后通过打开.xcworkspace文件打开项目


