module.exports = function(grunt) {

  require('load-grunt-tasks')(grunt);
  // Project configuration.
  grunt.initConfig({
    shell: {
      yarn_build: {
        command: 'yarn build --silent'
      }
    },
    execute: {
      buildRules: {
        src: ['node_modules/fireplan/fireplan'],
        options: {
          args: ['rules.yaml']
        }
      }
    },
  });

  grunt.registerTask('dist', [ 'shell:yarn_build', 'execute:buildRules' ]);
  grunt.registerTask('dist-enterprise', [ 'shell:yarn_build', 'execute:buildRules' ]);

};