   package JFDI::Devel::Halo;
   use base qw(HTML::Mason::Plugin);
   use Time::HiRes;

   sub start_component_hook {
       my ($self, $context) = @_;
        return if ( $context->comp->title eq '/autohandler' || $context->request->cgi_request->content_type !~ qr{text/html}i);
       $context->request->out(qq{<span class="halo" id="}.$context->comp->title.q{">});
       $context->request->out(qq{<span class="halo-args">}.YAML::Dump($context->args). q{</span>}) 
   }

   sub end_component_hook {
       my ($self, $context) = @_;
        return if ( $context->comp->title eq '/autohandler' || $context->request->cgi_request->content_type !~ qr{text/html}i);
       $context->request->out('</span>'); 
   }

1;
