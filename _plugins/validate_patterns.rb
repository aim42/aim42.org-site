# Runs tools/validate.rb in every Jekyll build (spec §9): any finding fails
# the build, also on hosts that only run a plain `jekyll build`.
require_relative "../tools/validate"

Jekyll::Hooks.register :site, :post_read do |site|
  errors = Aim42::Validator.new(site.source).run
  next if errors.empty?

  errors.each { |e| Jekyll.logger.error "aim42:", e }
  raise Jekyll::Errors::FatalException, "#{errors.size} invalid pattern finding(s), see above"
end
