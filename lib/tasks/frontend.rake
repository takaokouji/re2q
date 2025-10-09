# frozen_string_literal: true

namespace :frontend do
  # For convenience, npm packages do not have to be explicitly installed.
  # Installed will be automatically initiated by other tasks.
  desc "Install npm packages for the React app"
  task :npm_install do
    puts "Installing npm packages ..."
    Dir.chdir("#{Dir.pwd}/frontend") do
      system("npm", "install")
    end
  end

  # Run bin/rails frontend:dev to start the dev server.
  #
  # If you are using the Foreman gem, you might want to run
  # this task in the Procfile.
  #
  # bin/rails frontend:dev
  desc "Start React Development Server with Hot Module Reloading"
  task dev: [:npm_install] do
    puts "Starting React app development server..."
    Dir.chdir("#{Dir.pwd}/frontend") do
      system("npm", "run", "dev")
    end
  end

  # bin/rails frontend:typecheck
  desc "Check Typescript for the React App"
  task typecheck: [:npm_install] do
    puts "Check Typescript for React app..."
    Dir.chdir("#{Dir.pwd}/frontend") do
      system("npm", "run", "typecheck")
    end
  end

  # Run bin/rails frontend:build to build the production app.
  # The location of the build is defined in the
  # frontend/vite.config.ts file, and should
  # point to a location within the public folder.
  # Running bin/rails assets:precompile will also run this task.
  #
  # bin/rails frontend:build
  desc "Build React App and move to the public folder"
  task build: [:npm_install] do
    puts "Building React app..."
    Dir.chdir("#{Dir.pwd}/frontend") do
      system("npm", "run", "build")
    end

    # Rename index.html to frontend-index.html to prevent direct browser access
    # (must be accessed via FrontendController)
    index_path = "#{Dir.pwd}/public/frontend/index.html"
    renamed_path = "#{Dir.pwd}/public/frontend/frontend-index.html"
    if File.exist?(index_path)
      FileUtils.mv(index_path, renamed_path)
      puts "Renamed index.html to frontend-index.html"
    end

    puts "✅ React app successfully built and deployed!"
  end

  # Run bin/rails frontend:preview to create a preview build.
  #
  # This is identical to running bin/rails frontend:build
  # and is provided solely to align better with intent.
  desc "Preview your React App from the Rails development server (typically port 3000)"
  task preview: [:build]

  # Run bin/rails frontend:clobber to remove the build files.
  # Running bin/rails assets:clobber will also run this task.
  task :clobber do
    puts "Clobbering React app build files..."
    FileUtils.rm_rf("#{Dir.pwd}/public/frontend")
  end
end

# The following adds the above tasks to the regular
# assets:precompile and assets:clobber tasks.
#
# This means that any normal Rails deployment script which
# contains rake assets:precompile will also build the
# React app automatically.
Rake::Task["assets:precompile"].enhance(["frontend:build"])
Rake::Task["assets:clobber"].enhance(["frontend:clobber"])
