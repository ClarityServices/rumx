require './my_bean'
require './my_other_bean'

my_folder = Rumx::Beans::Folder.new
Rumx::Bean.root.bean_add_child(:MyFolder, my_folder)
my_folder.bean_add_child(:MyBean, MyBean.new)
my_folder.bean_add_child(:MyOtherBean, MyOtherBean.new)
