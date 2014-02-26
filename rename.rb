# == Dropbox Photo Rename
# Renames photos to have the same naming convention as dropbox
# <tt>YYYY-MM-DD HH.MM.SS.jpg</tt> format
#
# === To run:
# <tt>$ ruby FOLDERNAME</tt>
# It will also run recursively on all subfolders.

require 'exif_utility'

# Convert all of the files in a directory and then convert all of the subdirectories
def convert_directory(base_dir)

  subdirs = []
  pathnames = []
  Dir.foreach(base_dir) do |filename|
    pathname = File.join(base_dir, filename)

    # Ignore current folders and super folder
    next if filename == '.' or filename == '..'

    # Pull out subdirectories
    next if subdirs << pathname if File.directory?(pathname)

    # Act on all of the files
    # It's a jpg or jpeg file
    next if pathnames << pathname if File.file?(pathname) and (File.extname(pathname).downcase == '.jpg' or File.extname(pathname).downcase == '.jepg')

    # Otherwise it's something else, let the person know:
    puts "Non-JPG file found: #{pathname}"
  end

  rename_files(pathnames)

  subdirs.each { |dir| convert_directory(dir) }
end


def rename_files(pathnames)
  pathnames.each do |pathname|
    datetime = ExifUtility::ExifUtility.new(pathname).data.create_date

    # Convert to YYYY-MM-DD HH.MM.SS.jpg format
    set_filename(pathname, datetime.strftime("%Y-%m-%d %H.%M.%S") + ".jpg")
  end
end


# Check to make sure no filenames of that same name exist, if so add a counter to it
def set_filename(original_pathname, proposed_filename)
  pathname = File.join(File.dirname(original_pathname), proposed_filename)

  # Don't do anything if the current name of the file is the same as the proposed name,
  # the script is just getting run on pictures that already follow the naming convention.
  # This works because you can't have two of the same filenames, if there's another
  # picture with the same DateTime later the naming conventions will be corrected then.
  return if pathname == original_pathname

  # See if this isn't the first DateTime duplicate
  if File.exists?(File.basename(pathname, '.jpg') + '-1.jpg')
    count = 2
    while File.exists?(File.basename(pathname, '.jpg') + '-' + count + '.jpg')
      count += 1
    end
    File.rename(original_pathname, File.join(File.dirname(pathname), File.basename(pathname, '.jpg') + '-' + count + '.jpg'))
    return
  end

  # Potentially the first duplicate
  if File.exists?(pathname)
    # Rename the old (original) duplicate to have a '-1' at the end
    File.rename(pathname, File.join(File.dirname(pathname), File.basename(pathname, '.jpg') + '-1.jpg'))
    # Rename the duplicate that was just passed in
    File.rename(original_pathname, File.join(File.dirname(pathname), File.basename(pathname, '.jpg') + '-2.jpg'))
    return
  end

  # No duplicates exist so far, just rename it
  File.rename(original_pathname, pathname)

end

# run it
convert_directory(ARGV[0])