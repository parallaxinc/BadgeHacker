'' =================================================================================================
''
''   File....... jm_parser.spin
''   Purpose.... String parser for live commands or command files
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 20 OCT 2015
''
'' =================================================================================================

' 20 OCT 2015 -- added token_in_range() and copy_token()
' 07 OCT 2015 -- added quoted strings as single token
' 23 APR 2015 -- fixed enqueue_str for strings w/o CR or LF
' 25 MAR 2015 -- changed ucase to accept token index instead of string pointer
' 12 MAR 2015 -- updated tokens to 12  
' 11 MAR 2015 -- changed token length to accommdate indicated binary up to 32 bits


con

  BUF_SIZE = 79 + 1                                              ' size of input buffer + 0 terminator
  TOK_SIZE = 31 + 1                                              ' size of each token + 0 terminator

  MAX_TOKENS = 12                                                ' allowable tokens in string

  QUOTE = 34                                                     ' double quote mark

  CFLAG = %01                                                    ' valid character
  QFLAG = %10                                                    ' quote detected
  

obj

  str : "jm_strings"


var

  byte  queue[BUF_SIZE]                                          ' space for incoming characters
  byte  qidx                                                     ' buffer index
  byte  tokens[TOK_SIZE * MAX_TOKENS]                            ' space for parsed tokens

  long  p_vchars                                                 ' pointer to valid characters
  long  p_vtlist                                                 ' pointer to valid tokens list
  long  ntokens                                                  ' number of tokens in list
  long  csensitive

  long  tcount                                                   ' tokens in string


pub start(p_valid, p_tokens, ntoks, cs)

'' Configure parser
'' -- p_valid is pointer to string of valid characters
'' -- p_token is pointer to first token in valid token list
'' -- ntoks in number of tokesn in list
'' -- cs is case sensitivity (when false everything converted to uppercase)

  longmove(@p_vchars, @p_valid, 4)                               ' copy parameters

  reset                                                          ' clear everything


pub reset
                        
  bytefill(@queue, 0, BUF_SIZE + 1)                              ' clear string spaces
  bytefill(@tokens, 0, TOK_SIZE * MAX_TOKENS)


pub enqueue(c)

'' Adds character c to input queue
'' -- supports backspace for live input

  case c
    0, 13, 10:                                                   ' end of input?
      queue[qidx] := 0                                           ' terminate input
      ifnot (csensitive)                                         ' not case sensitive?
        str.ucstr(@queue)                                        ' covert to uppercase
      tcount := count_tokens(@queue)                             ' possible tokens in queue?
      if (tcount > 0)
        extract_all
        return true
      else
        reset

    8:                                                           ' backspace?
      if (qidx > 0)                                              ' if chars in queue
        queue[--qidx] := 0                                       ' back up and erase last

    other:
      queue[qidx++] := c                                         ' add to buffer
      if (qidx == BUF_SIZE)
        qidx -= 1

  return false                                                   ' no tokens yet


pub enqueue_str(p_str)

'' Adds string to input queue
'' -- preformatted string should include terminator (CR)

  repeat strsize(p_str) + 1                                      ' include trailing 0 (if no CR or LF)
    if (enqueue(byte[p_str++]))
      return true

  return false
  

pub queue_addr

'' Returns hub address of queue for external .str() methods

  return @queue
  
  
pub queue_len

'' Returns current length of input queue

  return strsize(@queue)


pub count_tokens(p_str) | toks, intoken, c, vchar

'' Returns count of possible tokens in string
'' -- does not compare to apps's token list

  toks := 0                                                      ' zero tokens
  intoken := %00                                                 ' not inside token

  repeat strsize(p_str)                                          ' iterate through string
    c := byte[p_str++]                                           ' get a character
    vchar := (str.first(c, p_vchars) => 0)                       ' in valid set
    ifnot (intoken)                                              ' if we're not in a token
      if (c == QUOTE)                                            ' is c a quote mark
        intoken := QFLAG                                         '  yes, flag it
        ++toks                                                   '  bump token count
      elseif (vchar)                                             ' valid character
        intoken := CFLAG                                         '  yes, flag it
        ++toks                                                   '  bump token count
    else
      if (intoken == QFLAG)                                      ' in a quoted token?
        if (c == QUOTE)                                          '  found end mark?
          intoken := %00                                         '  mark not in token
      else                                                       ' not in quoted token 
        if (vchar == false)                                      '  not in valid set
          intoken := %00                                         '  mark not in token

  return toks <# MAX_TOKENS


pub token_count

'' Returns token count
'' -- possible token count after count_tokens()
'' -- actual token count after extract_all 

  return tcount


pub extract_all | tidx, p_tok

'' Extract all (up to MAX_TOKENS) tokens from input queue

  bytefill(@tokens, 0, TOK_SIZE * MAX_TOKENS)                    ' clear tokens storage space

  tcount := count_tokens(@queue)                                 ' count tokens
  if (tcount == 0)                                               ' abort if no tokens in queue
    return

  repeat tidx from 0 to tcount-1
    extract_token(@queue, tidx)                                  ' extract token

  
pub extract_token(p_str, tidx) | target, intoken, c, vchar, p_tok, tlen

'' Extract token from buffer at p_str
'' -- tidx is the target token (0..N_TOKENS-1)

  if (tidx => MAX_TOKENS)                                        ' index is out-of-range
    return
  else
    target := tidx                                               ' copy token index

  intoken := %00                                                 ' not inside token

  repeat strsize(p_str)                                          ' iterate through buffer
    c := byte[p_str++]                                           ' get a character
    vchar := (str.first(c, p_vchars) => 0)                       ' in valid set        

    ifnot (intoken)                                              ' not in a token
      if (c == QUOTE)                                            ' start of quoted token?
        intoken := QFLAG                                         '  yes, mark
      elseif (vchar == true)                                     ' start of standard token?
        intoken := CFLAG                                         '  yes, mark

      if (intoken)                                               ' if new token
        if (target > 0)                                          '  and we're not at target
          --target                                               '   update
        else
          p_tok := token_addr(tidx)                              ' point to token storage      
          bytefill(p_tok, 0, TOK_SIZE)                           ' clear it
          if (c == QUOTE)                                        ' if quoted token
            c := byte[p_str++]                                   '  skip past quote
            if (c == QUOTE)                                      ' if empty quote
              return                                             '  we're done
          byte[p_tok++] := c                                     ' move char to token storage
          tlen := 1                                              ' initialize length
          repeat                                                 ' extract rest of token
            c := byte[p_str++]                                   ' get next char
            vchar := (str.first(c, p_vchars) => 0)               ' validate
            if ((intoken == QFLAG) and (c == QUOTE))             ' if in quoted token and end quote
              return                                             '  done
            elseif ((intoken == CFLAG) and (vchar == false))     ' if regular token and invalid char
              return                                             '  done
            else
              if (++tlen < TOK_SIZE)                             ' if space for new char  
                byte[p_tok++] := c                               '  add to token
              else                                               ' else
                return                                           '  done

    else
      if ((intoken == QFLAG) and (c == QUOTE))                   ' in quoted token and found end quote?
        intoken := %00
      elseif ((intoken == CFLAG) and (vchar == false))           ' in standard token and found space char?
        intoken := %00


pub token_addr(tidx)

'' Returns start address of token string
'' -- can return address of unused token

  if ((tidx => 0) and (tidx < MAX_TOKENS))                       ' if in token storage space
    return @tokens + (tidx * TOK_SIZE)                           ' return hub adddress
  else
    return -1 


pub token_len(tidx)

'' Returns length of token at tidx

  return strsize(token_addr(tidx))


pub copy_token(tidx, p_dest)

'' Copy token string to destination

  bytemove(p_dest, token_addr(tidx), token_len(tidx)+1) 

      
pub get_token_id(p_str) | p_tokens, tidx

'' Search known tokens list for string
'' -- returns index (0..ntokens-1) if found
'' -- returns -1 if no match

  if (p_vtlist < 0)                                              ' if no tokens list
    return -1                                                    '  we cannot id the token
  else
    p_tokens := p_vtlist                                         ' point to start of tokens list

  repeat tidx from 0 to ntokens-1                                ' iterate through known tokens
    if (strcomp(p_str, p_tokens))                                ' if match found
      return tidx                                                ' return token index
    else
      p_tokens += strsize(p_tokens) + 1                          ' advance to next token

  return -1


pub token_is_number(tidx)

'' Returns true if token at tidx is known number format
'' -- binary (%) and hex ($) values must be indicated (e.g., %1010 or $0A)

  return str.is_number(token_addr(tidx))


pub token_in_range(tidx, lo, hi) | v

'' Returns true if token at tidx is number in range lo..hi

  if (str.is_number(token_addr(tidx)))
    v := str.asc2val(token_addr(tidx))
    if ((v => lo) and (v =< hi))
      return true
    else
      return false


pub token_value(tidx)

'' Returns value of token at tidx
'' -- 0 if not a number
'' -- use token_is_number() before if 0 is valid

  if (token_is_number(tidx))
    return str.asc2val(token_addr(tidx))
  else
    return 0    
     

pub value(p_str)

'' Convert string to value
'' -- must be correctly formatted

  return str.asc2val(p_str)


pub ucase(tidx)

'' Converts token at tidx to upper case

  str.ucstr(token_addr(tidx))


dat { license }

{{

  Copyright (C) 2015 Jon McPhalen

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}  