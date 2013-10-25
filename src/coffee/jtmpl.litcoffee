<span>{></span> [jtmpl](/) <sup>0.2.0</sup>
===========================================

## Interface

### Compile:

String jtmpl(String template, AnyType model)

### Compile and bind (browser only):

void jtmpl(DOMElement target, String template, AnyType model)

`target` and `template` can be Strings in the format "#element-id".

### Main function



    jtmpl = (target, template, model, options) ->

      # Deprecated. `jtmpl(selector)`?
      if (target is null or typeof target is 'string') and not template?

        if not document?
          throw new Error(':( this API is only available in a browser')

        return apslice.call(document.querySelectorAll(target))

      # `jtmpl(template, model)`?
      if typeof target is 'string' and
          typeof template in ['number', 'string', 'boolean', 'object'] and
          (model is undefined or typeof model is 'object')

        options = model
        model = template
        template = target
        target = undefined

      # `jtmpl('#element-id', ...)`?
      if typeof target is 'string' and target.match(RE_NODE_ID)
        target = document.getElementById(target.substring(1))
      
      if not model?
        throw new Error(':( no model')

      # `jtmpl('#template-id', ...)` or `jtmpl(element, '#template-id', ...)`      
      if template.match and template.match(RE_NODE_ID)
        template = document.getElementById(template.substring(1)).innerHTML

      # options
      options = options or {}

      # string-separated opening and closing delimiter
      options.delimiters = (options.delimiters or '{{ }}').split(' ')
      # delimiters are changed in the generated HTML comment-enclosed section prototype
      # to avoid double-parsing
      options.compiledDelimiters = (options.compiledDelimiters or '<<< >>>').split(' ')

      # sections not enclosed in HTML tag are automatically enclosed
      options.defaultSection = options.defaultSectionTag or 'div'
      # default for section items
      options.defaultSectionItem = options.defaultSectionItem or 'div'
      # default for section items
      options.defaultVar = options.defaultVar or 'span'

      # default target tag
      options.defaultTargetTag = options.defaultTargetTag or 'div'

      delimiters = options.delimiters

      ## Preprocess template
      template = ('' + template)
        # Strip HTML comments that enclose tokens
        .replace(regexp("<!-- #{ RE_SPACE } ({{ #{ RE_ANYTHING } }}) #{ RE_SPACE } -->", delimiters), '$1')
        # Strip single quotes around html element attributes associated with tokens
        .replace(regexp("(#{ RE_IDENTIFIER })='({{ #{ RE_IDENTIFIER } }})'", delimiters), '$1=$2')
        # Strip double quotes around html element attributes associated with tags
        .replace(regexp("(#{ RE_IDENTIFIER })=\"({{ #{ RE_IDENTIFIER } }})\"", delimiters), '$1=$2')
        # If tags stand on their own line remove the line, keep the tag only
        .replace(regexp("\\n #{ RE_SPACE } ({{ #{ RE_ANYTHING } }}) #{ RE_SPACE } \\n", delimiters), '\n$1\n')

      # Compile template
      html = jtmpl.compile(template, model, null, false, delimiters, options.asArrayItem)

    this.jtmpl = jtmpl





## Rules

jtmpl is a processor of rules. There are two sequences,
one for each stage, compilation and binding.

Rules in each sequence are in increasing specificity order.

Both stages can be extended with new rules:
`jtmpl.compileRules.push({ ... })`, `jtmpl.bindRules.push({ ... })`





### Regular expression atoms

Used in various matchers

    RE_IDENTIFIER = '[\\w\\.\\-]+'
    RE_NODE_ID = '^#[\\w\\.\\-]+$'
    RE_ANYTHING = '[\\s\\S]*?'
    RE_SPACE = '\\s*'
    RE_DATA_JT = '(?: ( \\s* data-jt = " [^"]* )" )?'





### Compile rules 

Delimiters in `pattern`s are replaced with escaped options.delimiters, whitespace - stripped.

Inline tags implement `replaceWith`, section (block) tags implement `contents`.

Signatures:

[String, Array] `replaceWith` (String for each group in pattern, AnyType model)

[String, Array] `contents` (String template, AnyType model, String section)


    jtmpl.compileRules = [

      { # {{var}}
        pattern: "{{ (#{ RE_IDENTIFIER }) }}"
        wrapper: 'defaultVar'
        replaceWith: (prop, model) -> [escapeHTML(prop is '.' and model or model[prop]), []]
      }


      { # {{unescaped_var}}
        pattern: "{{ & (#{ RE_IDENTIFIER }) }}"
        wrapper: 'defaultVar'
        replaceWith: (prop, model) -> [prop is '.' and model or model[prop], []]
      }


      { # {{#section}}
        pattern: "{{ \\# (#{ RE_IDENTIFIER }) }}"
        wrapper: 'defaultSection'
        contents: (template, model, section) ->
          val = model[section]
          # Sequence?
          if Array.isArray(val)
            [ # template as HTML comment
              "<!-- # #{ template } -->" +
              # Render body for each item
              (jtmpl(template, item, { asArrayItem: true }) for item in val).join(''),
              []
            ]

          # Context?
          else if typeof val is 'object'
            # Render body using context
            [ jtmpl(template, val),
              []
            ]

          else
            [ jtmpl(template, model),
              if not val then ['style', 'display:none'] else []
            ]
      }


      { # {{^block}}
        pattern: "{{ \\^ (#{ RE_IDENTIFIER }) }}"
        wrapper: 'defaultSection'
        contents: (template, model, section) ->
          val = model[section]

          # Sequence?
          if Array.isArray(val)
            [ # template as HTML comment
              "<!-- ^ #{ template } -->"
              +
              # Render body if array empty
              if not val.length then jtmpl(template, model) else ''
              ,
              []
            ]

          else
            [ jtmpl(template, model),
              if val then ['style', 'display:none'] else []
            ]
      }


      { # attr={{prop}}
        pattern: "(#{ RE_IDENTIFIER }) = {{ (#{ RE_IDENTIFIER }) }}"
        replaceWith: (attr, prop, model) ->
          val = model[prop]
          # null?
          if not val? or val is null
            ['', []]
          # boolean?
          else if typeof val is 'boolean'
            [(if val then attr else ''), []]
          # quoted value
          else
            ["#{ attr }=\"#{ val }\"", []]
      }


      { # onevent={{func}}
        pattern: "on#{ RE_IDENTIFIER } = {{ #{ RE_IDENTIFIER } }}"
        replaceWith: -> ['', []]
      }


      { # class={{booleanVar}}
        pattern: "(class=\"? #{ RE_ANYTHING }) {{ (#{ RE_IDENTIFIER }) }}"
        replaceWith: (pre, prop, model) ->
          val = model[prop]
          [ # Emit match, and class name if true
            pre + (typeof val is 'boolean' and val and prop or '')
            ,
            []
          ]
      }
    ]





### Bind rules

Matching is done on tokenized data-jt items

`react` signature:

Function void (AnyType val) `react`
(DOMElement node, String for each pattern group, AnyType model)



    bindRules = [

      { # var
        pattern: "#{ RE_IDENTIFIER }",
        react: (node) ->
          (val) -> node.innerHTML = val
      }


      { # attr=var
        pattern: "(#{ RE_IDENTIFIER }) = #{ RE_IDENTIFIER }",
        react: (node, attr) ->
          (val) -> if node[attr] isnt val then node[attr] = val
      }


      { # class=var
        pattern: "class = (#{ RE_IDENTIFIER })",
        react: (node, prop, model) ->
          (val) -> (val and addClass or removeClass)(node, prop)
      }


      { # value/checked/selected=var
        pattern: "(value | checked | selected) = (#{ RE_IDENTIFIER })",
        react: (node, attr, prop, model) ->
          # attach DOM reactor

          # first select option?
          if node.nodeName is 'OPTION' and node.parentNode.querySelector('option') is node
            node.parentNode.addEventListener('change', ->
              idx = 0
              for option in node.parentNode.children
                if option.nodeName is 'OPTION'
                  model[prop] = option.selected
                  idx++
            )

          # radio group?
          if node.type is 'radio' and node.name
            node.addEventListener('change', ->
              if node[attr]
                for input in document.querySelectorAll("input[type=radio][name=#{ node.name }]")
                  if input isnt node
                    input.dispatchEvent(new Event('change'))
              model[prop] = node[attr]
            )

          # text input?
          if node.type is 'text'
            node.addEventListener('input', -> model[prop] = node[attr])

          # other inputs
          else
            node.addEventListener('change', -> model[prop] = node[attr])

          # return model reactor
          (val) -> if node[attr] isnt val then node[attr] = val
      }


    ]





## Compile rules processor

### Compile routine

Tokenize template and apply each rule

String  template
AnyType model
String  openTag
Boolean echoMode
Array   delimiters
Boolean asArrayItem


    jtmpl.compile = (template, model, openTag, echoMode, delimiters, asArrayItem) ->

      tokenizer = regexp("{{ (\/?) (#{ RE_ANYTHING }) }}", delimiters)
      result = ''
      pos = 0

      while (token = tokenizer.exec(template))

        # End block?
        if token[1]
          if token[2] isnt openTag
            throw new Error(openTag and
              ":( expected {{/#{ openTag }}}, got {{#{ token[2] }}}" or
              ":( unexpected {{/#{ token[2] }}}")
              
          # Exit recursion
          return result + template.slice(pos, tokenizer.lastIndex - token[0].length)

        slice = template.slice(pos, tokenizer.lastIndex)

        # Process rules in reverse order, most specific to least specific
        for rule in jtmpl.compileRules by -1

          match = regexp(rule.pattern, delimiters).exec(slice)
          if match
            result += slice.slice(pos, tokenizer.lastIndex - match[0].length)

            # inline tag or section?
            if rule.replaceWith? 
              if echoMode
                result += match[0]
              else
                [replaceWith, wrapperAttrs] =
                  rule.replaceWith(match.slice(1).concat([model])...)
                result += replaceWith

              pos = tokenizer.lastIndex

            else
              # Recursively get nested template (echoMode=on)
              tmpl = jtmpl.compile(
                template.slice(tokenizer.lastIndex), 
                model, match[1], true, delimiters)

              # Skip block contents
              tokenizer.lastIndex += tmpl.length

              # Match close block token
              closing = tokenizer.exec(template)
              pos = tokenizer.lastIndex

              if echoMode
                result += token[0] + tmpl + closing[0]
              else
                [contents, wrapperAttrs] = rule.contents(tmpl, model, match[1])
                result += contents

              # Match was found, skip other rules
            break

      # Return accumulated output
      result + template.slice(pos)




### Compiling phase supporting utilities

String addTagBinding(String, String)

Inject token in HTML element data-jt attribute.
Create attribute if not existent.

    injectTagBinding = (template, token) ->
      # group 1: capture 'data-jt' inject position
      # group 2: capture token inject position, if attribute exists
      match = template.match(regexp("^(< #{ RE_IDENTIFIER }) (#{ RE_ANYTHING }) #{ RE_DATA_JT } [^>]* >"))
      attrLen = (match[3] or '').length
      pos = match[1].length + match[2].length + attrLen
      # inject
      template.slice(0, pos) + ' ' + (attrLen and token or 'data-jt="' + token + '"') + template.slice(pos)



Int lastOpenedHTMLTag(String)

Return index of the last opening, maybe opened (no close brace), HTML tag
followed by end of string, or -1, if no such exists

    lastOpenedHTMLTag = (template) ->
      template.trimRight().search(regexp("< #{ RE_IDENTIFIER } [^>]*? >?$"))



Boolean isValidHTMLTag(String)

Check if contents is properly formatted closed HTML tag

    isValidHTMLTag = (contents) ->
      !!contents.trim().match(regexp("<(#{ RE_IDENTIFIER }) #{ RE_SPACE }
        [^>]*? > #{ RE_ANYTHING } </\\1> | < [^>]*? />")
      )





## Bind rules processor

Walk DOM and setup reactors between model and nodes.






## Supporting code


### Array shortcuts

    ap = Array.prototype
    apslice = ap.slice
    appop = ap.pop
    appush = ap.push
    apreverse = ap.reverse
    apshift = ap.shift
    apunshift = ap.unshift
    apsort = ap.sort


    


### Functional utilities

Function curry(Function f, AnyType frozenArg1, AnyType frozenArg2, ...)

    curry = ->
      args = apslice.call(arguments)
      ->
        args2 = apslice.call(arguments)
        args[0].apply(@, args.slice(1).concat(args2))


Function compose(Function f, Function g)

    compose = (f, g) -> -> f(g.apply(@, apslice.call(arguments)))




### Regular expression utilities

String escapeRE(String s)

Escape regular expression characters

    escapeRE = (s) -> (s + '').replace(/([.?*+^$[\]\\(){}|-])/g, '\\$1')




RegExp regexp(String src, Object options)

Replace mustaches with given delimiters, strip whitespace, return RegExp

    regexp = (src, delimiters) ->
      # strip whitespace
      src = src.replace(/\s+/g, '')
      new RegExp((if delimiters then src
        # triple mustache to alt non-escaped var output
        .replace('{{{', escapeRE(delimiters[0]) + '&')
        .replace('}}}', escapeRE(delimiters[1]))
        .replace('{{',  escapeRE(delimiters[0]))
        .replace('}}',  escapeRE(delimiters[1]))
        else src)
      , 'g')




### String utilities

String escapeHTML(String val)

Replace HTML special characters

    escapeHTML = (val) ->
      (val? and val or '')
        .toString()
        .replace /[&\"<>\\]/g, (s) ->
          switch s
            when '&' then '&amp;'
            when '\\'then '\\\\'
            when '"' then '\"'
            when '<' then '&lt;'
            when '>' then '&gt;'
            else s




### DOM utilities

DOMElement createSectionItem (DOMElement parent, AnyType context)

    createSectionItem = (parent, context) ->
      element = document.createElement('body')
      element.innerHTML = jtmpl(parent.getAttribute('data-jt-1') or '', context)
      element = element.children[0]
      jtmpl(element, element.innerHTML, context, { rootModel: model })
      element





### Binding utilities

void initBindings(Object context, String prop)

Create slots for property value and change reactor functions.
Setter notifies all reactors.

    initBindings = (context, prop) ->
      if not context["__#{ prop }_bindings"]
        Object.defineProperty(context, "__#{ prop }_bindings",
          enumerable: false
          writable: true
          value: []
        )
        Object.defineProperty(context, "__#{ prop }",
          enumerable: false
          writable: true
          value: context[prop]
        )
        Object.defineProperty(context, prop, 
          get: -> this["__#{ prop }"]
          set: (val) -> 
            this["__#{ prop }"] = val
            reactor.call(this, val) for reactor in this["__#{ prop }_bindings"]
        )




void bindArrayToNodeChildren(Array array, DOMElement node)

Bind an array to DOM node, 
so when array is modified, node children are updated accordingly.

Array is augmented by attaching listeners on existing indices
and setting a proxy for each mutable operation. 
`createSectionItem` is used for creating new items.


    bindArrayToNodeChildren = (array, node) ->

      # array already augmented?
      if not array.__garbageCollectNodes

        # it's possible for a referenced node to be destroyed. free the reference
        array.__garbageCollectNodes = ->
          i = this.__nodes.length
          while --i
            if not this.__nodes[i].parentNode
              this.__nodes.splice(i, 1)

        array.__removeEmpty = ->
          if not this.length then node.innerHTML = ''

        array.__addEmpty = ->
          if not this.length then node.innerHTML = jtmpl(node.getAttribute('data-jt-0') or '', {})

        # Mutable array operations

        array.pop = ->
          this.__removeEmpty()
          this.__garbageCollectNodes()
          node.removeChild(node.children[node.children.length - 1]) for node in this.__nodes
          appop.apply(this, arguments)
          appop.apply(this.__values, arguments)
          this.__addEmpty()

        array.push = (item) ->
          this.__removeEmpty()
          this.__garbageCollectNodes()
          node.appendChild(createSectionItem(node, item)) for node in this.__nodes
          appush.apply(this, arguments)
          len = this.__values.length
          result = appush.apply(this.__values, arguments)
          bindProp(item, len)
          result

        array.reverse = ->
          this.__removeEmpty()
          this.__garbageCollectNodes()
          result = apreverse.apply(this.__values, arguments)
          for node in this.__nodes
            node.innerHTML = ''
            for item, i in this.__values
              node.appendChild(createSectionItem(node, item))
              bindProp(item, i)
          this.__addEmpty()
          result

        array.shift = ->
          this.__removeEmpty()
          this.__garbageCollectNodes()
          apshift.apply(this, arguments)
          result = apshift.apply(this.__values, arguments)
          for node in this.__nodes
            node.removeChild(node.children[0])
          for item, i in this.__values
            bindProp(item, i)
          this.__addEmpty()
          result

        array.unshift = ->
          this.__removeEmpty()
          this.__garbageCollectNodes()
          for item in apslice.call(arguments).reverse()
            for node in this.__nodes
              node.insertBefore(createSectionItem(node, item), node.children[0])
          apunshift.apply(this, arguments)
          result = apunshift.apply(this.__values, arguments)
          for item, i in this.__values
            bindProp(item, i)
          this.__addEmpty()
          result

        array.sort = ->
          this.__removeEmpty()
          this.__garbageCollectNodes()
          apsort.apply(this, arguments)
          result = apsort.apply(this.__values, arguments)
          for node in this.__nodes
            node.innerHTML = ''
            for item, i in array
              node.appendChild(createSectionItem(node, item)) for node in this.__nodes
              bindProp(item, i)
          this.__addEmpty()
          result

        array.splice = (index, howMany) ->
          this.__removeEmpty()
          this.__garbageCollectNodes()
          for node in this.__nodes
            for i in [0...howMany]
              node.removeChild(node.children[index])
            for item in apslice.call(arguments, 2)
              node.insertBefore(createSectionItem(node, item), node.children[index])
              bindProp(item, index)
          apsplice.apply(this, arguments)
          apsplice.apply(this.__values, arguments)
          this.__addEmpty()

        # Bind property
        bindProp = (item, i) ->
          array.__values[i] = item
          Object.defineProperty(array, i, 
            get: -> this.__values[i]
            set: (val) -> 
              this.__garbageCollectNodes()
              this.__values[i] = val
              node.replaceChild(createSectionItem(node, val), node.children[i]) for node in this.__nodes
          )

        # bound nodes
        Object.defineProperty(array, '__nodes',
          enumerable: false
          writable: true
          value: []
        )
        # onchange handlers for each item
        Object.defineProperty(array, '__values',
          enumerable: false
          writable: true
          value: []
        )
        for item, i in array
          bindProp(item, i)

      if array.__nodes.indexOf(node) is -1 then array.__nodes.push(node)
      array