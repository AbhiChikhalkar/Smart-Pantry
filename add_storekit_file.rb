require 'xcodeproj'

project_path = 'SmartPantry.xcodeproj'
file_name = 'SmartPantry.storekit'
target_name = 'SmartPantry'

project = Xcodeproj::Project.open(project_path)
# Try to find the SmartPantry group
group = project.main_group.find_subpath('SmartPantry', false) || project.main_group

file_ref = group.files.find { |f| f.path == file_name }
unless file_ref
  file_ref = group.new_file(file_name)
  puts "Added file reference to project."
  
  target = project.targets.find { |t| t.name == target_name }
  if target
    # Add to Resources build phase
    target.add_resources([file_ref])
    puts "Added file to target resources."
  end
  
  project.save
  puts "Project saved."
else
  puts "File already exists in project."
end
