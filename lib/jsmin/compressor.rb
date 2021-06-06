class Compressor

  def initialize(in_device = $stdin, out_device = $stdout)
    @the_a = EOF
    @the_b = EOF
    @the_x = EOF
    @the_y = EOF
    @look_ahead = EOF
    @stdin = in_device
    @stdout = out_device
  end

  def error(string)
    #fputs("JSMIN Error: ", stderr);
    #fputs(string, stderr);
    #fputc('\n', stderr);
    #exit(1);
  end

  # is_alphanum -- return true if the character is a letter, digit, underscore,
  #     dollar sign, or non-ASCII character.
  def is_alphanum(codeunit)
    return (
      (codeunit >= 'a' && codeunit <= 'z') ||
        (codeunit >= '0' && codeunit <= '9') ||
        (codeunit >= 'A' && codeunit <= 'Z') ||
        codeunit == '_' ||
        codeunit == '$' ||
        codeunit == '\\' ||
        codeunit > 126
    )
  end

  # get -- return the next character from @stdin. Watch out for lookahead. If
  #     the character is a control character, translate it to a space or
  #     linefeed.
  def get
    codeunit = @look_ahead
    @look_ahead = EOF
    if (codeunit == EOF)
      codeunit = getc(@stdin);
    end
    if (codeunit >= ' ' || codeunit == '\n' || codeunit == EOF)
      return codeunit
    end
    if (codeunit == '\r')
      return '\n'
    end
    return ' '
  end

  #peek -- get the next character without advancing.
  def peek
    @look_ahead = get()
    return @look_ahead
  end

  # next -- get the next character, excluding comments. peek() is used to see
  #     if a '/' is followed by a '/' or '*'.
  def next()
    codeunit = get()
    if (codeunit == '/')
      case (peek())
      when '/'
        while (true) do
          codeunit = get();
          if (codeunit <= '\n')
            break
          end
        end
        break
      when '*'
        get();
        while (codeunit != ' ')
          case (get())
          when '*'
            if (peek() == '/')
              get();
              codeunit = ' '
            end
            break
          when EOF
            error("Unterminated comment.")
          end
        end
        break
      end
    end
    @the_y = @the_x
    @the_x = codeunit
    return codeunit
  end

  # action -- do something! What you do is determined by the argument:
  #     1   Output A. Copy B to A. Get the next B.
  #     2   Copy B to A. Get the next B. (Delete A).
  #     3   Get the next B. (Delete B).
  # action treats a string as a single character.
  # action recognizes a regular expression if it is preceded by the likes of
  # '(' or ',' or '='.
  def action(determined)
    case (determined)
    when 1
      #putc(@the_a, @stdout)
      @stdout.write(@the_a)
      if ((@the_y == '\n' || @the_y == ' ') &&
        (@the_a == '+' || @the_a == '-' || @the_a == '*' || @the_a == '/') &&
        (@the_b == '+' || @the_b == '-' || @the_b == '*' || @the_b == '/')
      )
        #putc(@the_y, @stdout)
        @stdout.write(@the_y)
      end
    when 2
      @the_a = @the_b;
      if (@the_a == '\'' || @the_a == '"' || @the_a == '`')
        while (true) do
          #putc(@the_a, @stdout)
          @stdout.write(@the_a)
          @the_a = get()
          if (@the_a == @the_b)
            break;
          end
          if (@the_a == '\\')
            #putc(@the_a, @stdout);
            @stdout.write(@the_a)
            @the_a = get();
          end
          if (@the_a == EOF)
            error("Unterminated string literal.");
          end
        end
      end
    when 3
      @the_b = next
      if (@the_b == '/' && (
        @the_a == '(' || @the_a == ',' || @the_a == '=' || @the_a == ':' ||
          @the_a == '[' || @the_a == '!' || @the_a == '&' || @the_a == '|' ||
          @the_a == '?' || @the_a == '+' || @the_a == '-' || @the_a == '~' ||
          @the_a == '*' || @the_a == '/' || @the_a == '{' || @the_a == '}' ||
          @the_a == ';'
      ))
        #putc(@the_a, @stdout)
        @stdout.write(@the_a)
        if (@the_a == '/' || @the_a == '*')
          #putc(' ', @stdout);
          @stdout.write(' ')
        end
        #putc(@the_b, @stdout);
        @stdout.write(@the_b)
        while (true) do
          @the_a = get();
          if (@the_a == '[')
            while true do
              #putc(@the_a, @stdout);
              @stdout.write(@the_a)
              @the_a = get();
              if (@the_a == ']')
                break;
              end
              if (@the_a == '\\')
                #putc(@the_a, @stdout);
                @stdout.write(@the_a)
                @the_a = get();
              end
              if (@the_a == EOF)
                error("Unterminated set in Regular Expression literal.");
              end
            end
          elsif (@the_a == '/')
            case (peek())
            when '/'
            when '*'
              error("Unterminated set in Regular Expression literal.");
            end
            break;
          elsif (@the_a == '\\')
            #putc(@the_a, @stdout);
            @stdout.write(@the_a)
            @the_a = get();
          end
          if (@the_a == EOF)
            error("Unterminated Regular Expression literal.");
          end
          #putc(@the_a, @stdout);
          @stdout.write(@the_a)
        end
        @the_b = next;
      end
    end
  end

  # jsmin -- Copy the input to the output, deleting the characters which are
  #     insignificant to JavaScript. Comments will be removed. Tabs will be
  #     replaced with spaces. Carriage returns will be replaced with linefeeds.
  #     Most spaces and linefeeds will be removed.
  def js_min
    if (peek() == 0xEF)
      get();
      get();
      get();
    end
    @the_a = '\n';
    action(3);
    while (@the_a != EOF) do
      case (@the_a)
      when ' '
        action(is_alphanum(@the_b) ? 1 : 2);
        break;
      when '\n'
        case (@the_b)
        when '{'
        when '['
        when '('
        when '+'
        when '-'
        when '!'
        when '~'
          action(1);
          break;
        when ' '
          action(3);
          break;
          default
          action(is_alphanum(@the_b) ? 1 : 2);
        end
        break;
        default
        case (@the_b)
        when ' '
          action(is_alphanum(@the_a) ? 1 : 3);
          break;
        when '\n'
          case (@the_a)
          when '}'
          when ']'
          when ')'
          when '+'
          when '-'
          when '"'
          when '\''
          when '`'
            action(1);
            break;
            default
            action(is_alphanum(@the_a) ? 1 : 3);
          end
          break;
          default
          action(1);
          break;
        end
      end
    end
  end

end