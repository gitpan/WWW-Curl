
/*
 * Perl interface for libcurl. Check out the file README for more info.
 */

/*
 * Copyright (C) 2000, 2001, 2002 Daniel Stenberg, Cris Bailiff, et al.  
 * You may opt to use, copy, modify, merge, publish, distribute and/or 
 * sell copies of the Software, and permit persons to whom the 
 * Software is furnished to do so, under the terms of the MPL or
 * the MIT/X-derivate licenses. You may pick one of these licenses.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>
#include <curl/easy.h>

#if (LIBCURL_VERSION_NUM<0x070702)
#define CURLOPT_HEADERFUNCTION 20079
#define header_callback_func write_callback_func
#else
#define header_callback_func writeheader_callback_func
#endif

typedef enum {
    CALLBACK_WRITE = 0,
    CALLBACK_READ,
    CALLBACK_HEADER,
    CALLBACK_PROGRESS,
    CALLBACK_PASSWD,
    CALLBACK_LAST
} perl_curl_easy_callback_code;

typedef enum {
    SLIST_HTTPHEADER = 0,
    SLIST_QUOTE,
    SLIST_POSTQUOTE,
    SLIST_LAST
} perl_curl_easy_slist_code;

typedef struct {
    /* The main curl handle */
    struct CURL *curl;

    /* Lists that can be set via curl_easy_setopt() */
    struct curl_slist *slist[SLIST_LAST];
    SV *callback[CALLBACK_LAST];
    SV *callback_ctx[CALLBACK_LAST];

    /* copy of error buffer var for caller*/
    char errbuf[CURL_ERROR_SIZE+1];
    char *errbufvarname;

#ifdef WITH_INTERNAL_VARS
#define USE_INTERNAL_VARS 0x01
    /* Internal content storing */
    char *contbuf;
    char *bufptr;
    size_t bufsize;
    size_t contlen;
    int internal_options;
#endif

} perl_curl_easy;

#if LIBCURL_VERSION_NUM >= 0x070900
typedef struct {
    struct HttpPost * post;
    struct HttpPost * last;
} perl_curl_form;
#else
typedef struct {
    void * post;
    void * last;
} perl_curl_form;
#endif

/* switch from curl option codes to the relevant callback index */
static perl_curl_easy_callback_code callback_index(int option) {
    switch(option) {
	case CURLOPT_WRITEFUNCTION:
	case CURLOPT_FILE:
	    return CALLBACK_WRITE;
	    break;

	case CURLOPT_READFUNCTION:
	case CURLOPT_INFILE:
	    return CALLBACK_READ;
	    break;

	case CURLOPT_HEADERFUNCTION:
	case CURLOPT_WRITEHEADER:
	    return CALLBACK_HEADER;
	    break;

	case CURLOPT_PROGRESSFUNCTION:
	case CURLOPT_PROGRESSDATA:
	    return CALLBACK_PROGRESS;
	    break;

	case CURLOPT_PASSWDFUNCTION:
	case CURLOPT_PASSWDDATA:
	    return CALLBACK_PASSWD;
	    break;
    }
    croak("Bad callback index requested\n");
    return CALLBACK_LAST;
}

/* switch from curl slist names to an slist index */
static perl_curl_easy_slist_code slist_index(int option) {
    switch(option) {
	case CURLOPT_HTTPHEADER:
	    return SLIST_HTTPHEADER;
	    break;
	case CURLOPT_QUOTE:
	    return SLIST_QUOTE;
	    break;
	case CURLOPT_POSTQUOTE:
	    return SLIST_POSTQUOTE;
	    break;
    }
    croak("Bad slist index requested\n");
    return SLIST_LAST;
}

/* Setup these global vars */
static perl_curl_easy * perl_curl_easy_new()
{
    perl_curl_easy *self;
    Newz(1, self, 1, perl_curl_easy);
    if (!self)
	croak("out of memory");
    self->curl=curl_easy_init();
    return self;
}

static perl_curl_easy * perl_curl_easy_duphandle(perl_curl_easy *orig)
{
    perl_curl_easy *self;
    Newz(1, self, 1, perl_curl_easy);
    if (!self)
	croak("out of memory");
    self->curl=curl_easy_duphandle(orig->curl);
    return self;
}

static void perl_curl_easy_delete(perl_curl_easy *self)
{
    perl_curl_easy_slist_code index;
    if (self->curl) 
        curl_easy_cleanup(self->curl);

    for (index=0;index<SLIST_LAST;index++) {
	if (self->slist[index]) curl_slist_free_all(self->slist[index]);
    };

    if (self->errbufvarname) free(self->errbufvarname);

#ifdef WITH_INTERNAL_VARS
    if (self->contbuf) free(self->contbuf);
    self->bufptr = self->contbuf = NULL;
#endif

    Safefree(self);

}

/* Register a callback function */

static void perl_curl_easy_register_callback(perl_curl_easy *self, SV **callback, SV *function)
{
    /* FIXME: need to check the ref-counts here */
    if (*callback == NULL) {
	*callback = newSVsv(function);
    } else {
	SvSetSV(*callback, function);
    }
}

static perl_curl_form * perl_curl_form_new()
{
    perl_curl_form *self;
    Newz(1, self, 1, perl_curl_form);
    if (!self)
	croak("out of memory");
    self->post=NULL;
    self->last=NULL;
    return self;
}

static void perl_curl_form_delete(perl_curl_form *self)
{
#if LIBCURL_VERSION_NUM >= 0x070900
    if (self->post) {
	curl_formfree(self->post);
    }
#endif
    Safefree(self);
}

/* generic fwrite callback, which decides which callback to call */
static size_t
fwrite_wrapper (const void *ptr,
		size_t size,
		size_t nmemb,
		perl_curl_easy *self,
		void *call_function,
		void *call_ctx)
{
    dSP;

    if (call_function) { /* We are doing a callback to perl */
	int count, status;
	SV *sv;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	if (ptr) {
	    XPUSHs(sv_2mortal(newSVpvn((char *)ptr, (STRLEN)(size * nmemb))));
	} else { /* just in case */
	    XPUSHs(&PL_sv_undef);
	}

	if (call_ctx) {
	    XPUSHs(sv_2mortal(newSVsv(call_ctx)));
        } else { /* should be a stdio glob ? */
	    XPUSHs(&PL_sv_undef);
	}

	PUTBACK;
	count = perl_call_sv((SV *) call_function, G_SCALAR);
	SPAGAIN;

	if (count != 1)
            croak("callback for CURLOPT_WRITEFUNCTION didn't return a status\n");

	status = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;
	return status;

    } else {
	/* perform write directly, via PerlIO */

	PerlIO *handle;
	if (call_ctx) { /* Assume the context is a GLOB */
	    handle = IoOFP(sv_2io(call_ctx));
	} else { /* punt to stdout */
	    handle = PerlIO_stdout();
	}
	return PerlIO_write(handle,ptr,size*nmemb);
    }
}

/* Write callback for calling a perl callback */
size_t
write_callback_func( const void *ptr, size_t size, size_t nmemb, void *stream)
{
    perl_curl_easy *self;
    self=(perl_curl_easy *)stream;
    return fwrite_wrapper(ptr,size,nmemb,self,
        self->callback[CALLBACK_WRITE],self->callback_ctx[CALLBACK_WRITE]);
}

/* header callback for calling a perl callback */
size_t
writeheader_callback_func(const void *ptr, size_t size, size_t nmemb, void *stream)
{
    perl_curl_easy *self;
    self=(perl_curl_easy *)stream;

    return fwrite_wrapper(ptr,size,nmemb,self,
        self->callback[CALLBACK_HEADER],self->callback_ctx[CALLBACK_HEADER]);
}

/* read callback for calling a perl callback */
size_t
read_callback_func( void *ptr, size_t size, size_t nmemb, void *stream)
{
    dSP ;

    size_t maxlen;
    perl_curl_easy *self;
    self=(perl_curl_easy *)stream;

    maxlen = size*nmemb;

    if (self->callback[CALLBACK_READ]) { /* We are doing a callback to perl */
	char *data;
	int count;
	SV *sv;
	STRLEN len;

        ENTER ;
        SAVETMPS ;
 
        PUSHMARK(SP) ;

	if (self->callback_ctx[CALLBACK_READ]) {
            sv = self->callback_ctx[CALLBACK_READ];
        } else {
            sv = &PL_sv_undef;
        }
	
        XPUSHs(sv_2mortal(newSViv(maxlen)));
        XPUSHs(sv_2mortal(newSVsv(sv)));

        PUTBACK ;
        count = perl_call_sv(self->callback[CALLBACK_READ], G_SCALAR);
        SPAGAIN;

        if (count != 1)
            croak("callback for CURLOPT_READFUNCTION didn't return any data\n");

        sv = POPs;
        data = SvPV(sv,len);

        /* only allowed to return the number of bytes asked for */
        len = (len<maxlen ? len : maxlen);
        /* memcpy(ptr,data,(size_t)len); */
        Copy(data,ptr,len,char);

        PUTBACK ;
        FREETMPS ;
        LEAVE ;
        return (size_t) (len/size);

    } else {
	/* read input directly */
	PerlIO *f;
	if (self->callback_ctx[CALLBACK_READ]) { /* hope its a GLOB! */
	    f = IoIFP(sv_2io(self->callback_ctx[CALLBACK_READ]));
	} else { /* punt to stdin */
	    f = PerlIO_stdin();
	}
	return PerlIO_read(f,ptr,maxlen);
    }
}

/* Progress callback for calling a perl callback */

static int progress_callback_func(void *clientp, double dltotal, double dlnow,
    double ultotal, double ulnow)
{
    dSP;

    int count;
    perl_curl_easy *self;
    self=(perl_curl_easy *)clientp;

    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    if (self->callback_ctx[CALLBACK_PROGRESS]) {
	XPUSHs(sv_2mortal(newSVsv(self->callback_ctx[CALLBACK_PROGRESS])));
    } else {
	XPUSHs(&PL_sv_undef);
    }
    XPUSHs(sv_2mortal(newSVnv(dltotal)));
    XPUSHs(sv_2mortal(newSVnv(dlnow)));
    XPUSHs(sv_2mortal(newSVnv(ultotal)));
    XPUSHs(sv_2mortal(newSVnv(ulnow)));
    
    PUTBACK;
    count = perl_call_sv(self->callback[CALLBACK_PROGRESS], G_SCALAR);
    SPAGAIN;

    if (count != 1)
	croak("callback for CURLOPT_PROGRESSFUNCTION didn't return 1\n");

    count = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
    return count;
}


/* Password callback for calling a perl callback */

static int passwd_callback_func(void *clientp, char *prompt, char *buffer, int buflen)
{
    dSP;
    char *data;
    SV *sv;
    STRLEN len;
    int count;

    perl_curl_easy *self;
    self=(perl_curl_easy *)clientp;

    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    if (self->callback_ctx[CALLBACK_PASSWD]) {
        XPUSHs(sv_2mortal(newSVsv(self->callback_ctx[CALLBACK_PASSWD])));
    } else {
	XPUSHs(&PL_sv_undef);
    }
    XPUSHs(sv_2mortal(newSVpv(prompt, 0)));
    XPUSHs(sv_2mortal(newSViv(buflen)));
    PUTBACK;
    count = perl_call_sv(self->callback[CALLBACK_PASSWD], G_ARRAY);
    SPAGAIN;
    if (count != 2)
	croak("callback for CURLOPT_PASSWDFUNCTION didn't return status + data\n");

    sv = POPs;
    count = POPi;

    data = SvPV(sv,len);
 
    /* only allowed to return the number of bytes asked for */
    len = (len<(buflen-1) ? len : (buflen-1));
    memcpy(buffer,data,len);
    buffer[buflen]=0; /* ensure C string terminates */

    PUTBACK;
    FREETMPS;
    LEAVE;
    return count;
}


#if 0
/* awaiting closepolicy prototype */
int 
closepolicy_callback_func(void *clientp)
{
   dSP;
   int argc, status;
   SV *pl_status;

   ENTER;
   SAVETMPS;

   PUSHMARK(SP);
   PUTBACK;

   argc = perl_call_sv(closepolicy_callback, G_SCALAR);
   SPAGAIN;

   if (argc != 1) {
      croak("Unexpected number of arguments returned from closefunction callback\n");
   }
   pl_status = POPs;
   status = SvTRUE(pl_status) ? 0 : 1;

   PUTBACK;
   FREETMPS;
   LEAVE;

   return status;
}
#endif


/* FIXME: should do this in the perl layer */
/* Internal write callback. Only used if USE_INTERNAL_VARS was specified */

#ifdef WITH_INTERNAL_VARS
static size_t internal_write_callback(const void *ptr, size_t size, size_t num, void *stream)
{
    perl_curl_easy *self;
    self=(perl_curl_easy *)stream;
   
    size *= num;
    if ((self->contlen + size) >= self->bufsize) {
	if (self->bufsize) {
	    self->bufsize *= 2; /* grow */
	} else {
	    self->bufsize = 32768; /* initial size */
	}
	self->contbuf = realloc(self->contbuf, self->bufsize + 1);
	self->bufptr = self->contbuf + self->contlen;
    }
    self->contlen += size;
    memcpy(self->bufptr, ptr, size);
    self->bufptr += size;
    *(self->bufptr) = '\0';
    return size;
}
#endif

#include "curlopt-constants.c"

typedef perl_curl_easy * WWW__Curl__easy;

typedef perl_curl_form * WWW__Curl__form;

MODULE = WWW::Curl 	PACKAGE = WWW::Curl::easy 	PREFIX = curl_easy_

BOOT:
        curl_global_init(CURL_GLOBAL_ALL); /* FIXME: does this need a mutex for ithreads? */


PROTOTYPES: ENABLE

int
constant(name,arg)
    char * name
    int arg


void
curl_easy_init(...)
    ALIAS:
	new = 1
    PREINIT:
	perl_curl_easy *self;
	char *sclass = "WWW::Curl::easy";
    PPCODE:
    	if (items>0 && !SvROK(ST(0))) {
	    STRLEN dummy;
	    sclass = SvPV(ST(0),dummy);
	}

	self=perl_curl_easy_new(); /* curl handle created by this point */

	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), sclass, (void*)self);
	SvREADONLY_on(SvRV(ST(0)));

	/* configure curl to always callback to the XS interface layer */
	curl_easy_setopt(self->curl, CURLOPT_WRITEFUNCTION, write_callback_func);
	curl_easy_setopt(self->curl, CURLOPT_READFUNCTION, read_callback_func);
	curl_easy_setopt(self->curl, CURLOPT_HEADERFUNCTION, header_callback_func);
	curl_easy_setopt(self->curl, CURLOPT_PROGRESSFUNCTION, progress_callback_func);
	curl_easy_setopt(self->curl, CURLOPT_PASSWDFUNCTION, passwd_callback_func);

	/* set our own object as the context for all curl callbacks */
	curl_easy_setopt(self->curl, CURLOPT_FILE, self); 
	curl_easy_setopt(self->curl, CURLOPT_INFILE, self); 
	curl_easy_setopt(self->curl, CURLOPT_WRITEHEADER, self); 
	curl_easy_setopt(self->curl, CURLOPT_PROGRESSDATA, self); 
	curl_easy_setopt(self->curl, CURLOPT_PASSWDDATA, self); 

	/* we always collect this, in case it's wanted */
	curl_easy_setopt(self->curl, CURLOPT_ERRORBUFFER, self->errbuf);

	XSRETURN(1);

void
curl_easy_duphandle(self)
    WWW::Curl::easy self
    PREINIT:
	perl_curl_easy *clone;
	char *sclass = "WWW::Curl::easy";
	perl_curl_easy_callback_code i;
    PPCODE:
	clone=perl_curl_easy_duphandle(self);

	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), sclass, (void*)clone);
	SvREADONLY_on(SvRV(ST(0)));

	/* configure curl to always callback to the XS interface layer */
	/*
	 * FIXME: This needs more testing before turning on... 
	 
	curl_easy_setopt(clone->curl, CURLOPT_WRITEFUNCTION, write_callback_func);
	curl_easy_setopt(clone->curl, CURLOPT_READFUNCTION, read_callback_func);
	curl_easy_setopt(clone->curl, CURLOPT_HEADERFUNCTION, header_callback_func);
	curl_easy_setopt(clone->curl, CURLOPT_PROGRESSFUNCTION, progress_callback_func);
	curl_easy_setopt(clone->curl, CURLOPT_PASSWDFUNCTION, passwd_callback_func);
	*/

	/* set our own object as the context for all curl callbacks */
	curl_easy_setopt(clone->curl, CURLOPT_FILE, clone); 
	curl_easy_setopt(clone->curl, CURLOPT_INFILE, clone); 
	curl_easy_setopt(clone->curl, CURLOPT_WRITEHEADER, clone); 
	curl_easy_setopt(clone->curl, CURLOPT_PROGRESSDATA, clone); 
	curl_easy_setopt(clone->curl, CURLOPT_PASSWDDATA, clone); 

	/* we always collect this, in case it's wanted */
	curl_easy_setopt(clone->curl, CURLOPT_ERRORBUFFER, clone->errbuf);

	for(i=0;i<CALLBACK_LAST;i++) {
	    clone->callback[i]=self->callback[i]; 
	    clone->callback_ctx[i]=self->callback_ctx[i]; 
	     /*
	      * FIXME: 
    	    perl_curl_easy_register_callback(clone,&(clone->callback[i]), self->callback[i]);
    	    perl_curl_easy_register_callback(clone,&(clone->callback_ctx[i]), self->callback_ctx[i]);
	    */
	};

	XSRETURN(1);

char *
curl_easy_version(...)
    CODE:
	RETVAL=curl_version();
    OUTPUT:
	RETVAL

int
curl_easy_setopt(self, option, value)
	WWW::Curl::easy self
	int option
	SV * value
    CODE:
	RETVAL=CURLE_OK;
	switch(option) {
	/* SV * to user contexts for callbacks - any SV (glob,scalar,ref) */
	case CURLOPT_FILE:
	case CURLOPT_INFILE:
	case CURLOPT_WRITEHEADER:
	case CURLOPT_PROGRESSDATA:
	case CURLOPT_PASSWDDATA:
	    perl_curl_easy_register_callback(self,&(self->callback_ctx[callback_index(option)]),value);
	    break;

	/* SV * to a subroutine ref */
	case CURLOPT_WRITEFUNCTION:
	case CURLOPT_READFUNCTION:
        case CURLOPT_HEADERFUNCTION:
	case CURLOPT_PROGRESSFUNCTION:
	case CURLOPT_PASSWDFUNCTION:
	    perl_curl_easy_register_callback(self,&(self->callback[callback_index(option)]),value);
	    break;

	/* slist cases */
	case CURLOPT_HTTPHEADER:
	case CURLOPT_QUOTE:
	case CURLOPT_POSTQUOTE:
	    {
		/* This is an option specifying a list, which we put in a curl_slist struct */
		AV *array = (AV *)SvRV(value);
		struct curl_slist **slist = NULL;
		int last = av_len(array);
		int i;

		/* We have to find out which list to use... */
		slist = &(self->slist[slist_index(option)]);

		/* free any previous list */
		if (*slist) {
		    curl_slist_free_all(*slist);
		    *slist=NULL;
		}                                                                       
		/* copy perl values into this slist */
		for (i=0;i<=last;i++) {
		    SV **sv = av_fetch(array,i,0);
		    int len = 0;
		    char *string = SvPV(*sv, len);
		    if (len == 0) /* FIXME: is this correct? */
			break;
		    *slist = curl_slist_append(*slist, string);
		}
		/* pass the list into curl_easy_setopt() */
		RETVAL = curl_easy_setopt(self->curl, option, *slist);
	    };
	    break;

	/* Pass in variable name for storing error messages. Yuck. */
	case CURLOPT_ERRORBUFFER:
	    {
		STRLEN dummy;
		if (self->errbufvarname) free(self->errbufvarname);
		self->errbufvarname = strdup((char *)SvPV(value, dummy));
	    };
	    break;

        /* tell curl to redirect STDERR - value should be a glob */
	case CURLOPT_STDERR:
	    RETVAL = curl_easy_setopt(self->curl, option, IoOFP(sv_2io(value)) );
	    break;

	/* not working yet...
	case CURLOPT_HTTPPOST:
	    if (sv_derived_from(value, "WWW::Curl::form")) {
		WWW__Curl__form wrapper;
		IV tmp = SvIV((SV*)SvRV(value));
		wrapper = INT2PTR(WWW__Curl__form,tmp);
		RETVAL = curl_easy_setopt(self->curl, option, wrapper->post);
	    } else
		croak("value is not of type WWW::Curl::form"); 
	    break;
        */

	/* default cases */
	default:
	    if (option < CURLOPTTYPE_OBJECTPOINT) { /* An integer value: */
		RETVAL = curl_easy_setopt(self->curl, option, (long)SvIV(value));
	    } else { /* A char * value: */
		/* FIXME: Does curl really want NULL for empty stings? */
		STRLEN dummy;
		char *pv = SvPV(value, dummy);
		RETVAL = curl_easy_setopt(self->curl, option, *pv ? pv : NULL);
	    };
	    break;
	};
    OUTPUT:
	RETVAL

int
internal_setopt(self, option, value)
	WWW::Curl::easy self
	int option
	int value
    CODE:
#ifdef WITH_INTERNAL_VARS
	if (value == 1) {
	    self->internal_options |= option;
	} else {
	    self->internal_options &= !option;
	}
#else
	croak("internal_setopt deprecated - recompile with -DWITH_INTERNAL_VARS for support\n");
#endif
	RETVAL = 0;
    OUTPUT:
	RETVAL

int
curl_easy_perform(self)
	WWW::Curl::easy self
    CODE:
	/* perform the actual curl fetch */
#ifdef WITH_INTERNAL_VARS
	if (self->internal_options & USE_INTERNAL_VARS) {
	    /* Use internal callback which just stores the content into a buffer. */
	    self->bufptr = self->contbuf;
	    self->contlen = 0;
	    curl_easy_setopt(self->curl, CURLOPT_WRITEFUNCTION, internal_write_callback);
	    curl_easy_setopt(self->curl, CURLOPT_HEADER, 1);
	}
#endif
	RETVAL = curl_easy_perform(self->curl);

	if (RETVAL && self->errbufvarname) {
	    /* If an error occurred and a varname for error messages has been
	       specified, store the error message. */
	    SV *sv = perl_get_sv(self->errbufvarname, TRUE | GV_ADDMULTI);
	    sv_setpv(sv, self->errbuf);
	}
	/* Better to use plain perl for this - should work, but I have no scripts
	 * using this to test with. */
#ifdef WITH_INTERNAL_VARS
	if ((!RETVAL || (RETVAL == CURLE_PARTIAL_FILE)) &&
	   (self->internal_options & USE_INTERNAL_VARS)) {
	    /* No error and internal variable for the content are to be used:
	       Split the data into headers and content and store them into
	       perl variables. */
	    /* Note these are globals, and therefore are not safe between handles
	     * or threads */
	    SV *head_sv = perl_get_sv("WWW::Curl::easy::headers", TRUE | GV_ADDMULTI);
	    SV *cont_sv = perl_get_sv("WWW::Curl::easy::content", TRUE | GV_ADDMULTI);
	    char *p = self->contbuf;
	    int nl = 0, found = 0;
	    while (p < self->bufptr) {
		if (nl && (*p == '\n' || *p == '\r')) {
		/* found empty line, end of headers */
		*p++ = '\0';
		sv_setpv(head_sv, self->contbuf);
		while (*p == '\n' || *p == '\r') {
			p++;
		}
		sv_setpvn(cont_sv, p, self->bufptr - p);
		found = 1;
		break;
		}
		nl = (*p == '\n');
		p++;
	    }
	    if (!found) {
		sv_setpv(head_sv, "");
		sv_setpvn(cont_sv, self->contbuf, self->contlen);
	    }
	}
	/* reset */
	self->bufptr = self->contbuf;
	self->contlen = 0;
#endif
    OUTPUT:
	RETVAL


SV *
curl_easy_getinfo(self, option, ... )
	WWW::Curl::easy self
	int option
    CODE:
	switch (option & CURLINFO_TYPEMASK) {
	    case CURLINFO_STRING:
	    {
		char * vchar;
		curl_easy_getinfo(self->curl, option, &vchar);
		RETVAL = newSVpv(vchar,0);
		break;
	    }
	    case CURLINFO_LONG:
	    {
		long vlong;
		curl_easy_getinfo(self->curl, option, &vlong);
		RETVAL = newSViv(vlong);
		break;
	    }
	    case CURLINFO_DOUBLE:
	    {
		double vdouble;
		curl_easy_getinfo(self->curl, option, &vdouble);
		RETVAL = newSVnv(vdouble);
		break;
	    }
	    default: {
		RETVAL = newSViv(CURLE_BAD_FUNCTION_ARGUMENT);
		break;
	    }
	}
	if (items > 2) 
	    sv_setsv(ST(2),RETVAL);
    OUTPUT:
	RETVAL

char *
curl_easy_errbuf(self)
	WWW::Curl::easy self
    CODE:
    	RETVAL = self->errbuf;
    OUTPUT:
	RETVAL

int
curl_easy_cleanup(self)
	WWW::Curl::easy self
    CODE:
    	/* does nothing anymore - cleanup is automatic when a curl handle goes out of scope */
	RETVAL = 0;
    OUTPUT:
	RETVAL

void
curl_easy_DESTROY(self)
	WWW::Curl::easy self
    CODE:
        perl_curl_easy_delete(self);

void
curl_easy_global_cleanup()
    CODE:
    curl_global_cleanup();


MODULE = WWW::Curl 	PACKAGE = WWW::Curl::form 	PREFIX = curl_form_

void
curl_form_new(...)
    PREINIT:
	perl_curl_form *self;
	char *sclass = "WWW::Curl::form";
    PPCODE:
	if (items>0 && !SvROK(ST(0))) {
	    STRLEN dummy;
	    sclass = SvPV(ST(0),dummy);
	}

	self=perl_curl_form_new();

	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), sclass, (void*)self);
	SvREADONLY_on(SvRV(ST(0)));

	XSRETURN(1);

void
curl_form_add(self,name,value)
    WWW::Curl::form self
    char *name
    char *value
    CODE:
#if LIBCURL_VERSION_NUM >= 0x070900
#if 0
	curl_formadd(&(self->post),&(self->last),
		CURLFORM_COPYNAME,name,
		CURLFORM_COPYCONTENTS,value,
		CURLFORM_END); 
#endif
#endif

void
curl_form_addfile(self,filename,description,type)
    WWW::Curl::form self
    char *filename
    char *description
    char *type
    CODE:
#if LIBCURL_VERSION_NUM >= 0x070900
#if 0
	curl_formadd(&(self->post),&(self->last),
		CURLFORM_FILE,filename,
		CURLFORM_COPYNAME,description,
		CURLFORM_CONTENTTYPE,type,
		CURLFORM_END); 
#endif
#endif

void
curl_form_DESTROY(self)
	WWW::Curl::form self
    CODE:
        perl_curl_form_delete(self);
