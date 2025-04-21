# (Linux篇)申请azure for students获取多年免费vps并搭建访外线路  
如果你有一个edu邮箱为何不试一试呢。
## 1、访问[这里：学生Azure](https://azure.microsoft.com/zh-cn/free/students)  
点击"免费开始使用"，一步一步按照指引填写你的学校邮箱即可。  
可以参考这篇文章：[知乎-申请azure for students](https://zhuanlan.zhihu.com/p/629311513)  
如果你可以申请下来就继续，大部分edu邮箱都能秒过。  
## 2、创建免费linux虚拟机  
访问这个链接可以跳过各种可能会掉进的付费的坑：  
[Create your free linux vms](https://portal.azure.com/#create/microsoft.freeaccountvirtualmachine-linux)  
直接点"创建"就好。  
![image](https://github.com/user-attachments/assets/848c3b01-7567-44a5-94f0-c527dfa4ad57)  
按照下图填写虚拟机信息：  
![image](https://github.com/user-attachments/assets/a198808c-112d-4698-bc82-a7d51fceb854)
![image](https://github.com/user-attachments/assets/ed092d63-06bb-4697-a84b-de3709ad6d81)  
然后直接点击"查看+创建"就行。  
## 3、连接到你的虚拟机  
访问[azure虚拟机面板](https://portal.azure.com/#browse/Microsoft.Compute%2FVirtualMachines)以选中你的虚拟机。  
如果你没有域名你可以创建一个dns配置：  
![image](https://github.com/user-attachments/assets/8a8fd403-3b23-4d3f-a6db-9909628f1ad2)
点击配置后可以自选一个域名来代替你的公共ip：
![image](https://github.com/user-attachments/assets/fa0ec880-402a-428d-9417-66ee35ca7cb0)
然后回到本机，打开你的cmd，输入
'''code
ssh 你之前输入的用户名@你刚才设置的dns地址
'''
这样可以通过ssh连接到你的虚拟机。  
![image](https://github.com/user-attachments/assets/d71fac51-cf43-4d9f-96bb-9d4c53065ddb)
然后输入你的密码就好，没有回显，放心输入后回车即可。
如果你没有安装ssh请自行安装。
## 4、安装 xray + nginx + certbot (推荐配置)  
### 4.0、老生常谈
'''code
sudo apt update
sudo apt upgrade
'''
### 4.1、安装certbot

### 4.2、安装Xray([官方教程](https://xtls.github.io/document/install.html#linux-%E5%AE%89%E8%A3%85%E6%96%B9%E5%BC%8F))  
可以直接使用xray官方Linux安装脚本：
'''code
sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
'''
### 4.3、安装nginx
