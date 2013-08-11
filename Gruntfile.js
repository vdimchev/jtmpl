module.exports = function(grunt) {

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    concat: {
      options: {
        separator: ';\n'
      },
      dist: {
        src: ['src/**/*.js', 'components/Object.observe/Object.observe.poly.js'],
        dest: 'js/jtmpl.js'
      }
    },

    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("dd-mm-yyyy") %> */\n'
      },
      dist: {
        files: {
          'js/<%= pkg.name %>.min.js': ['<%= concat.dist.dest %>']
        }
      }
    },

    qunit: {
      files: ['test/**/*.html']
    },

    jshint: {
      files: ['gruntfile.js', 'src/**/*.js', 'test/**/*.js'],
      options: {
        // options here to override JSHint defaults
        globals: {
          jQuery: true,
          console: true,
          module: true,
          document: true
        }
      }
    },

    less: {
      css: {
        src: ['src/less/*.less'],
        dest: 'css/styles.css',
      }
    },

    watch: {
      jshint: {
        files: ['<%= jshint.files %>'],
        tasks: ['jshint', 'concat', 'uglify']
      },
      less: {
        files: ['src/less/*.less'],
        tasks: ['less']
      },
      readme: {
        files: ['README.md'],
        tasks: ['copy', 'dotlit', 'md2html', 'clean'],
        options: {
          nospawn: true
        }
      }
    },

    connect: {
      server: {
        options: {
          port: 8000,
          base: './',
        }
      }
    },

    copy: {
      main: { 
        files: [
          {src: 'README.md', dest: 'kitchensink.html.lit.md'},
          {src: 'components/highlightjs/highlight.pack.js', dest: 'js/highlight.min.js'},
          {src: 'components/highlightjs/styles/solarized_dark.css', dest: 'css/highlight.css'},
          {src: 'components/baseline/examples/baseline.css', dest: 'css/baseline.css'}
        ]
      }
    },

    dotlit: {
      options: {
        verbose: true,
        extractAll: true
      },
      files: ['*.lit.md']
    },

    md2html: {
      index: {
        options: {},
        files: [{
          src: ['README.md'],
          dest: 'index.html'
        }]
      }
    },

    clean: ['kitchensink.html.lit.md']    

  });

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-qunit');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-dotlit');
  grunt.loadNpmTasks('grunt-md2html');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-css');

  grunt.registerTask('test', ['jshint', 'qunit']);
  grunt.registerTask('default', ['jshint', 'concat', 'uglify', 'copy', 'dotlit', 'md2html', 'clean', 'connect', 'watch']);

};