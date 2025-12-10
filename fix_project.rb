require 'xcodeproj'

project_path = 'SmartPantry.xcodeproj'
file_path = 'SmartPantry/SmartPantry.storekit'

project = Xcodeproj::Project.open(project_path)
group = project.main_group["SmartPantry"]

# Check if file already exists using a simple name check on children
existing_ref = group.children.find { |child| child.path == 'SmartPantry.storekit' }

if existing_ref
  puts "File reference already exists."
else
  # Add the file reference
  file_ref = group.new_reference('SmartPantry.storekit')
  puts "Added file reference: #{file_ref}"
  
  # Ensure it is in the target resources
  target = project.targets.find { |t| t.name == 'SmartPantry' }
  target.add_resources([file_ref])
  puts "Added to target resources."
  
  project.save
  puts "Project saved successfully."
end
