platform :osx, '10.10'
use_frameworks!

def pods_for_errbody
	pod 'BuildaUtils', '0.0.4'
end

def also_xcode_pods
	pods_for_errbody
	pod 'XcodeServerSDK', '0.1.5'
end

target 'Buildasaur' do
	also_xcode_pods
end

target 'buildasaur-cli' do
	also_xcode_pods
end

target 'BuildaKit' do
	also_xcode_pods
end

target 'BuildaKitTests' do
	also_xcode_pods
end

target 'BuildaGitServer' do
	pods_for_errbody
end

target 'BuildaGitServerTests' do
	pods_for_errbody
end



