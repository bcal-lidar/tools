function DirectoryFromFile, fileName
  lastIndex = STRPOS(fileName, '/', /REVERSE_SEARCH)
  
  if (lastIndex EQ -1) THEN BEGIN 
  ;search for windows style path
    lastIndex = STRPOS(filename, '\', /REVERSE_SEARCH)
  endif
  
  Directory = STRMID(fileName, 0, lastIndex+1)
  return, Directory
    
end
