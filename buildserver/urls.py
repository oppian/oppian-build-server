from django.conf import settings
from django.conf.urls.defaults import *
from django.contrib import admin
admin.autodiscover()


urlpatterns = patterns('',
    (r'^', include('loki.urls')),

)
# static media content through Django ONLY for development
if settings.DEBUG == True:
    mediapatterns = patterns('django.views',
        (r'^%sjs/(?P<path>.*)$' % settings.MEDIA_URL, 'static.serve',
            {'document_root': '%sjs' % settings.STATIC_DOC_ROOT}),
        (r'^%scss/(?P<path>.*)$' % settings.MEDIA_URL, 'static.serve',
            {'document_root': '%scss' % settings.STATIC_DOC_ROOT}),
        (r'^%simages/(?P<path>.*)$' % settings.MEDIA_URL, 'static.serve',
            {'document_root': '%simages' % settings.STATIC_DOC_ROOT}),
            
        (r'^%s/(?P<path>.*)$' % settings.ADMIN_MEDIA_PREFIX, 'static.serve',
            {'document_root': '%simages' % settings.ADMIN_MEDIA_ROOT}),
    )
    # put media patterns first sunce loki has a catch all
    mediapatterns += urlpatterns
    urlpatterns = mediapatterns
