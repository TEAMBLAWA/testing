module.exports = function(grunt) {

  require('load-grunt-tasks')(grunt);
  // Project configuration.
  grunt.initConfig({
    shell: {
      yarn_build: {
        command: 'yarn build --silent'
      }
    }
  });

  grunt.registerTask('dist', [ 'shell:yarn_build' ]);
  grunt.registerTask('dist-enterprise', [ 'shell:yarn_build' ]);

};