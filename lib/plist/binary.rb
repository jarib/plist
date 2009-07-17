require "date"
require "nkf"
require "set"
require "stringio"

module Plist
  module Binary
    def self.binary_plist(obj)
      encoded_objs = flatten_collection(obj)
      encoded_objs.collect! {|o| binary_plist_obj(o)}
      # Write header and encoded objects.
      plist = "bplist00" + encoded_objs.join
      # Write offset table.
      offset_table_addr = plist.length
      offset = 8
      encoded_objs.each do |o|
        plist += [offset >> 32, offset & 0xffffffff].pack("NN")
        offset += o.length
      end
      # Write trailer.
      plist += "\0\0\0\0\0\0" # Six unused bytes
      plist += [
        8, # Byte size of offsets
        4, # Byte size of object references in arrays, sets, and dictionaries
        encoded_objs.length >> 32, encoded_objs.length & 0xffffffff,
        0, 0, # Index of root object
        offset_table_addr >> 32, offset_table_addr & 0xffffffff
      ].pack("CCNNNNNN")
      plist
    end
    
    CFBinaryPlistMarkerNull = 0x00
    CFBinaryPlistMarkerFalse = 0x08
    CFBinaryPlistMarkerTrue = 0x09
    CFBinaryPlistMarkerFill = 0x0F
    CFBinaryPlistMarkerInt = 0x10
    CFBinaryPlistMarkerReal = 0x20
    CFBinaryPlistMarkerDate = 0x33
    CFBinaryPlistMarkerData = 0x40
    CFBinaryPlistMarkerASCIIString = 0x50
    CFBinaryPlistMarkerUnicode16String = 0x60
    CFBinaryPlistMarkerUID = 0x80
    CFBinaryPlistMarkerArray = 0xA0
    CFBinaryPlistMarkerSet = 0xC0
    CFBinaryPlistMarkerDict = 0xD0
    NSTimeIntervalSince1970 = 978307200.0
    
    def self.flatten_collection(collection, obj_list = [], id_refs = {})
      case collection
      when Array, Set
        if id_refs[collection.object_id]
          return obj_list[id_refs[collection.object_id]]
        end
        obj_refs = collection.class.new
        id_refs[collection.object_id] = obj_list.length
        obj_list << obj_refs
        collection.each do |obj|
          flatten_collection(obj, obj_list, id_refs)
          obj_refs << id_refs[obj.object_id]
        end
        return obj_list
      when Hash
        if id_refs[collection.object_id]
          return obj_list[id_refs[collection.object_id]]
        end
        obj_refs = {}
        id_refs[collection.object_id] = obj_list.length
        obj_list << obj_refs
        collection.each do |key, value|
          flatten_collection(key, obj_list, id_refs)
          flatten_collection(value, obj_list, id_refs)
          obj_refs[id_refs[key.object_id]] = id_refs[value.object_id]
        end
        return obj_list
      else
        unless id_refs[collection.object_id]
          id_refs[collection.object_id] = obj_list.length
          obj_list << collection
        end
        return obj_list
      end
    end
    
    def self.binary_plist_obj(obj)
      case obj
      when String
        encoding = NKF.guess2(obj)
        if [NKF::ASCII, NKF::BINARY, NKF::UNKNOWN].include?(encoding)
          result = (CFBinaryPlistMarkerASCIIString |
            (obj.length < 15 ? obj.length : 0xf)).chr
          result += binary_plist_obj(obj.length) if obj.length >= 15
          result += obj
          return result
        else
          # Convert to UTF8.
          if encoding == NKF::UTF8
            utf8 = obj
          else
            utf8 = NKF.nkf("-m0 -w", obj)
          end
          # Decode each character's UCS codepoint.
          codepoints = []
          i = 0
          while i < utf8.length
            byte = utf8[i]
            if byte & 0xe0 == 0xc0
              codepoints << ((byte & 0x1f) << 6) + (utf8[i+1] & 0x3f)
              i += 1
            elsif byte & 0xf0 == 0xe0
              codepoints << ((byte & 0xf) << 12) + ((utf8[i+1] & 0x3f) << 6) +
                (utf8[i+2] & 0x3f)
              i += 2
            elsif byte & 0xf8 == 0xf0
              codepoints << ((byte & 0xe) << 18) + ((utf8[i+1] & 0x3f) << 12) +
                ((utf8[i+2] & 0x3f) << 6) + (utf8[i+3] & 0x3f)
              i += 3
            else
              codepoints << byte
            end
            i += 1
          end
          # Return string of 16-bit codepoints.
          data = codepoints.pack("n*")
          result = (CFBinaryPlistMarkerUnicode16String |
            (codepoints.length < 15 ? codepoints.length : 0xf)).chr
          result += binary_plist_obj(codepoints.length) if codepoints.length >= 15
          result += data
          return result
        end
      when Float
        return (CFBinaryPlistMarkerReal | 3).chr + [obj].pack("G")
      when Integer
        if obj <= 0xff
          nbytes = 1
          size_bits = 0
        elsif obj <= 0xffff
          nbytes = 2
          size_bits = 1
        elsif obj <= 0xffffffff
          nbytes = 4
          size_bits = 2
        elsif obj <= 0xffffffffffffffff
          nbytes = 8
          size_bits = 3
        elsif obj <= 0xffffffffffffffffffffffffffffffff # yes, really
          nbytes = 16
          size_bits = 4
        else
          raise(RangeError, "integer too big - exceeds 128 bits")
        end
        words = [obj >> 96, (obj >> 64) & 0xffffffff, (obj >> 32) & 0xffffffff,
          obj & 0xffffffff]
        huge_num = words.pack("NNNN")
        return (CFBinaryPlistMarkerInt | size_bits).chr + huge_num[-nbytes, nbytes]
      when TrueClass
        return CFBinaryPlistMarkerTrue.chr
      when FalseClass
        return CFBinaryPlistMarkerFalse.chr
      when Time
        return CFBinaryPlistMarkerDate.chr +
          [obj.to_f - NSTimeIntervalSince1970].pack("G")
      when IO, StringIO
        obj.rewind
        return binary_plist_data(obj.read)
      when Array
        # Must be an array of object references as returned by flatten_collection.
        result = (CFBinaryPlistMarkerArray | (obj.length < 15 ? obj.length : 0xf)).chr
        result += binary_plist_obj(obj.length) if obj.length >= 15
        result += obj.pack("N*")
      when Set
        # Must be a set of object references as returned by flatten_collection.
        result = (CFBinaryPlistMarkerSet | (obj.length < 15 ? obj.length : 0xf)).chr
        result += binary_plist_obj(obj.length) if obj.length >= 15
        result += obj.to_a.pack("N*")
      when Hash
        # Must be a table of object references as returned by flatten_collection.
        result = (CFBinaryPlistMarkerDict | (obj.length < 15 ? obj.length : 0xf)).chr
        result += binary_plist_obj(obj.length) if obj.length >= 15
        result += obj.to_a.flatten.pack("N*")
      else
        return binary_plist_data(Marshal.dump(obj))
      end
    end
    
    def self.binary_plist_data(data)
      result = (CFBinaryPlistMarkerData |
        (data.length < 15 ? data.length : 0xf)).chr
      result += binary_plist_obj(data.length) if data.length > 15
      result += data
      return result
    end
  end
end
