require "json"
require "kemal-session"

class Session
  class FileSystemEngine < Engine
    class StorageInstance
      macro define_storage(vars)
        JSON.mapping({
          {% for name, type in vars %}
               {{name.id}}s: Hash(String, {{type}}),
          {% end %}
        })

        {% for name, type in vars %}
          @{{name.id}}s = Hash(String, {{type}}).new
          getter {{name.id}}s

          def {{name.id}}(k : String) : {{type}}
            return @{{name.id}}s[k]
          end

          def {{name.id}}?(k : String) : {{type}}?
            return @{{name.id}}s[k]?
          end

          def {{name.id}}(k : String, v : {{type}})
            @{{name.id}}s[k] = v
          end
        {% end %}

        def initialize
          {% for name, type in vars %}
            @{{name.id}}s = Hash(String, {{type}}).new
          {% end %}
        end
      end

      define_storage({
        int: Int32,
        bigint: Int64,
        string:  String,
        float:   Float64,
        bool: Bool,
        #object: Session::StorableObject,
      })
    end

    @cache : StorageInstance
    @cached_session_id : String

    def initialize(options : Hash(Symbol, String))
      # @TODO make options optional (default value for sessions_dir = ./sessions/, maybe add format option (json, yaml...))
      raise ArgumentError.new("FileSystemEngine: Mandatory option sessions_dir not set") unless options.has_key? :sessions_dir
      raise ArgumentError.new("FileSystemEngine: Cannot write to directory #{options[:sessions_dir]}") unless File.directory?(options[:sessions_dir]) && File.writable?(options[:sessions_dir])
      @sessions_dir = uninitialized String
      @sessions_dir = options[:sessions_dir]

      @cache = StorageInstance.new
      @cached_session_id = ""
    end

    def run_gc
      Dir.foreach(@sessions_dir) do |f|
        full_path = @sessions_dir + f
        if File.file? full_path
          age = Time.utc_now - File.stat(full_path).mtime # mtime is always saved in utc
          File.delete full_path if age.total_seconds > Session.config.timeout.total_seconds
        end
      end
    end

    def create_session(session_id : String)
      read_or_create_storage_instance(session_id)
    end

    def get_session(session_id : String)
      read_or_create_storage_instance(session_id)
    end

    def destroy_session(session_id : String)
      full_path = @sessions_dir + @cached_session_id + ".json"
      if File.file? full_path
        File.delete(full_path)
      end
    end

    def destroy_all_sessions
      Dir.foreach(@sessions_dir) do |f|
        full_path = @sessions_dir + f
        if File.file? full_path && full_path.match(/\.json/)
          File.delete full_path
        end
      end
    end

    def each_session
      @store.each do |key, val|
        yield Session.new(key)
      end
    end

    def all_sessions
      files = Dir.entries(@sessions_dir)
      files.each do |file|
        arr << file if file.match(/\.json/)
      end
    end

    def load_into_cache(session_id : String) : StorageInstance
      @cached_session_id = session_id
      return @cache = read_or_create_storage_instance(session_id)
    end

    def is_in_cache?(session_id : String) : Bool
      return session_id == @cached_session_id
    end

    def save_cache
      File.write(@sessions_dir + @cached_session_id + ".json", @cache.to_json)
    end

    def read_or_create_storage_instance(session_id : String) : StorageInstance
      if File.file? @sessions_dir + session_id + ".json"
         # File.open(@sessions_dir + session_id + ".json","w"){} # should update filemtime when session is read
        return StorageInstance.from_json(File.read(@sessions_dir + session_id + ".json"))
      else
        instance = StorageInstance.new
        File.write(@sessions_dir + session_id + ".json", instance.to_json)
        return instance
      end
    end

    # Delegating int(k,v), int?(k) etc. from Engine to StorageInstance
    macro define_delegators(vars)
      {% for name, type in vars %}

        def {{name.id}}(session_id : String, k : String) : {{type}}
          load_into_cache(session_id) unless is_in_cache?(session_id)
          return @cache.{{name.id}}(k)
        end

        def {{name.id}}?(session_id : String, k : String) : {{type}}?
          load_into_cache(session_id) unless is_in_cache?(session_id)
          return @cache.{{name.id}}?(k)
        end

        def {{name.id}}(session_id : String, k : String, v : {{type}})
          load_into_cache(session_id) unless is_in_cache?(session_id)
          @cache.{{name.id}}(k, v)
          save_cache
        end

        def {{name.id}}s(session_id : String) : Hash(String, {{type}})
          load_into_cache(session_id) unless is_in_cache?(session_id)
          return @cache.{{name.id}}s
        end
      {% end %}
    end

    define_delegators({
      int: Int32,
      bigint: Int64,
      string: String,
      float: Float64,
      bool: Bool,
      object: Session::StorableObject
    })
  end
end
