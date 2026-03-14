import Foundation

enum WebViewJS {
    static let inputHandlerScript: String = """
        (function() {
            var focusedElement = null;

            if (typeof window.__useCustomKeyboard === 'undefined') {
                window.__useCustomKeyboard = false;
            }

            document.addEventListener('focusin', function(event) {
                try {
                    const target = event.target;
                    if (!(target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')) {
                        return;
                    }

                    if (!window.__useCustomKeyboard) {
                        focusedElement = null;
                        return;
                    }

                    focusedElement = target;
                    target.setAttribute('readonly', 'readonly');
                    target.setAttribute('inputmode', 'none');
                    target.style.caretColor = 'transparent';
                    window.webkit.messageHandlers.inputFocused.postMessage('focused');
                } catch (_) {}
            });

            document.addEventListener('focusout', function(event) {
                try {
                    if (!window.__useCustomKeyboard) {
                        return;
                    }

                    const target = event.target;
                    if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') {
                        if (focusedElement === target) {
                            focusedElement = null;
                        }
                        window.webkit.messageHandlers.inputBlurred.postMessage('blurred');
                    }
                } catch (_) {}
            });

            window.customInsertText = function(text) {
                if (!window.__useCustomKeyboard || !focusedElement) {
                    return;
                }

                focusedElement.removeAttribute('readonly');
                const start = focusedElement.selectionStart || 0;
                const end = focusedElement.selectionEnd || 0;
                const value = focusedElement.value || '';
                focusedElement.value = value.substring(0, start) + text + value.substring(end);
                focusedElement.selectionStart = focusedElement.selectionEnd = start + text.length;
                focusedElement.setAttribute('readonly', 'readonly');

                if (text === '\\n') {
                    submitForm();
                }
            };

            window.customDeleteText = function() {
                if (!window.__useCustomKeyboard || !focusedElement) {
                    return;
                }

                focusedElement.removeAttribute('readonly');
                const start = focusedElement.selectionStart || 0;
                const end = focusedElement.selectionEnd || 0;
                const value = focusedElement.value || '';
                if (start > 0) {
                    focusedElement.value = value.substring(0, start - 1) + value.substring(end);
                    focusedElement.selectionStart = focusedElement.selectionEnd = start - 1;
                }
                focusedElement.setAttribute('readonly', 'readonly');
            };

            function submitForm() {
                if (!focusedElement) {
                    return;
                }

                const form = focusedElement.closest('form');
                if (form) {
                    form.submit();
                    return;
                }

                const searchButton = document.querySelector('input[type="submit"]')
                    || document.querySelector('button[type="submit"]')
                    || document.querySelector('[aria-label*="検索"]')
                    || document.querySelector('[aria-label*="Search"]');

                if (searchButton) {
                    searchButton.click();
                    return;
                }

                const googleSearchButton = document.querySelector('input[name="btnK"]')
                    || document.querySelector('.FPdoLc input[type="submit"]')
                    || document.querySelector('[data-ved] input[type="submit"]');

                if (googleSearchButton) {
                    googleSearchButton.click();
                }
            }
        })();
    """

    static let navigationGuardScript: String = """
        (function() {
            try {
                if (window.__navGuardInstalled) {
                    return;
                }

                window.__navGuardInstalled = true;
                if (typeof window.__confirmNavOn === 'undefined') {
                    window.__confirmNavOn = false;
                }
                var pendingForm = null;
                var suppressInterception = false;

                function absoluteURL(value) {
                    try {
                        return new URL(value, location.href).href;
                    } catch (_) {
                        return null;
                    }
                }

                function isSearchEngineHost(host) {
                    if (!host) {
                        return false;
                    }

                    const normalizedHost = String(host).toLowerCase();
                    return normalizedHost === 'www.google.com'
                        || normalizedHost === 'google.com'
                        || normalizedHost.endsWith('.google.com')
                        || normalizedHost === 'www.bing.com'
                        || normalizedHost === 'bing.com'
                        || normalizedHost === 'search.yahoo.co.jp'
                        || normalizedHost === 'yahoo.co.jp'
                        || normalizedHost.endsWith('.yahoo.co.jp');
                }

                function shouldInterceptNavigation(urlValue) {
                    if (!window.__confirmNavOn) {
                        return false;
                    }

                    if (suppressInterception) {
                        return false;
                    }

                    if (isSearchEngineHost(location.host)) {
                        return false;
                    }

                    const absolute = absoluteURL(urlValue);
                    if (!absolute) {
                        return false;
                    }

                    try {
                        const target = new URL(absolute);
                        const currentHost = String(location.host || '').toLowerCase();
                        const targetHost = String(target.host || '').toLowerCase();
                        return currentHost !== targetHost;
                    } catch (_) {
                        return false;
                    }
                }

                function stopEvent(event) {
                    try { event.preventDefault(); } catch (_) {}
                    try { event.stopPropagation(); } catch (_) {}
                    try {
                        if (typeof event.stopImmediatePropagation === 'function') {
                            event.stopImmediatePropagation();
                        }
                    } catch (_) {}
                }

                function postConfirmation(payload) {
                    try {
                        if (!window.webkit || !window.webkit.messageHandlers || !window.webkit.messageHandlers.confirmNav) {
                            return false;
                        }
                        window.webkit.messageHandlers.confirmNav.postMessage(payload);
                        return true;
                    } catch (_) {
                        return false;
                    }
                }

                document.addEventListener('click', function(event) {
                    try {
                        const anchor = event.target && event.target.closest ? event.target.closest('a[href]') : null;
                        if (!anchor) {
                            return;
                        }

                        const href = anchor.getAttribute('href');
                        if (!href || /^(javascript:|mailto:|tel:)/i.test(href)) {
                            return;
                        }

                        const target = anchor.getAttribute('target');
                        if (target && target !== '_self') {
                            return;
                        }

                        const absolute = absoluteURL(href);
                        if (!absolute) {
                            return;
                        }

                        if (!shouldInterceptNavigation(absolute)) {
                            return;
                        }

                        stopEvent(event);
                        postConfirmation({ type: 'anchor', url: absolute, from: location.host });
                    } catch (_) {}
                }, true);

                document.addEventListener('submit', function(event) {
                    try {
                        const form = event.target;
                        if (!form || form.tagName !== 'FORM') {
                            return;
                        }

                        const action = form.getAttribute('action') || location.href;
                        const absolute = absoluteURL(action);
                        if (!absolute || !shouldInterceptNavigation(absolute)) {
                            return;
                        }

                        pendingForm = form;
                        stopEvent(event);
                        postConfirmation({ type: 'form', url: absolute, from: location.host });
                    } catch (_) {}
                }, true);

                const originalPushState = history.pushState;
                history.pushState = function(state, title, url) {
                    try {
                        if (url && shouldInterceptNavigation(url)) {
                            const absolute = absoluteURL(url);
                            if (absolute && postConfirmation({ type: 'history', method: 'push', url: absolute, from: location.host })) {
                                return;
                            }
                        }
                    } catch (_) {}

                    return originalPushState.apply(this, arguments);
                };

                const originalReplaceState = history.replaceState;
                history.replaceState = function(state, title, url) {
                    try {
                        if (url && shouldInterceptNavigation(url)) {
                            const absolute = absoluteURL(url);
                            if (absolute && postConfirmation({ type: 'history', method: 'replace', url: absolute, from: location.host })) {
                                return;
                            }
                        }
                    } catch (_) {}

                    return originalReplaceState.apply(this, arguments);
                };

                const originalFormSubmit = HTMLFormElement.prototype.submit;
                HTMLFormElement.prototype.submit = function() {
                    try {
                        const action = this.getAttribute('action') || location.href;
                        const absolute = absoluteURL(action);
                        if (absolute && shouldInterceptNavigation(absolute)) {
                            pendingForm = this;
                            if (postConfirmation({ type: 'form', url: absolute, from: location.host })) {
                                return;
                            }
                        }
                    } catch (_) {}

                    return originalFormSubmit.apply(this, arguments);
                };

                const locationPrototype = Object.getPrototypeOf(window.location);
                const originalLocationAssign = locationPrototype.assign;
                const originalLocationReplace = locationPrototype.replace;

                locationPrototype.assign = function(url) {
                    try {
                        const absolute = absoluteURL(url);
                        if (absolute && shouldInterceptNavigation(absolute)) {
                            if (postConfirmation({ type: 'location', method: 'assign', url: absolute, from: location.host })) {
                                return;
                            }
                        }
                    } catch (_) {}

                    return originalLocationAssign.call(this, url);
                };

                locationPrototype.replace = function(url) {
                    try {
                        const absolute = absoluteURL(url);
                        if (absolute && shouldInterceptNavigation(absolute)) {
                            if (postConfirmation({ type: 'location', method: 'replace', url: absolute, from: location.host })) {
                                return;
                            }
                        }
                    } catch (_) {}

                    return originalLocationReplace.call(this, url);
                };

                window.__proceedNav = function(payload) {
                    try {
                        const type = payload && payload.type;
                        const method = payload && payload.method;
                        const url = payload && payload.url;
                        if (!url) {
                            return;
                        }

                        suppressInterception = true;

                        if (type === 'history') {
                            if (method === 'replace') {
                                originalReplaceState.call(history, {}, '', url);
                            } else {
                                originalPushState.call(history, {}, '', url);
                            }
                        } else if (type === 'form') {
                            const form = pendingForm;
                            pendingForm = null;
                            if (form) {
                                originalFormSubmit.call(form);
                            } else {
                                originalLocationAssign.call(window.location, url);
                            }
                        } else if (type === 'location') {
                            if (method === 'replace') {
                                originalLocationReplace.call(window.location, url);
                            } else {
                                originalLocationAssign.call(window.location, url);
                            }
                        } else {
                            originalLocationAssign.call(window.location, url);
                        }
                    } catch (_) {}
                    finally {
                        setTimeout(function() {
                            suppressInterception = false;
                        }, 0);
                    }
                };
            } catch (_) {}
        })();
    """

    static func muteScript(_ muted: Bool) -> String {
        let flag = muted ? "true" : "false"
        return """
        (function(){try{
          var m=
        """ + flag + """
        ;window.__appMuted=m;
          var apply=function(el){try{if(!el)return; if(m){ if(el.dataset.prevvol===undefined){el.dataset.prevvol=el.volume;} el.muted=true; el.volume=0; } else { el.muted=false; if(el.dataset.prevvol!==undefined){el.volume=Number(el.dataset.prevvol); delete el.dataset.prevvol;} else { el.volume=1; } }}catch(e){}};
          var list=document.querySelectorAll('audio,video'); if(list){ list.forEach(apply); }
          if(!window.__appMuteInstalled){ window.__appMuteInstalled=true;
            var obs=new MutationObserver(function(muts){ muts.forEach(function(mu){ (mu.addedNodes||[]).forEach(function(n){ try{ if(n && (n.tagName==='AUDIO'||n.tagName==='VIDEO')){ apply(n); } else if(n && n.querySelectorAll){ n.querySelectorAll('audio,video').forEach(apply); } }catch(e){} }); }); });
            obs.observe(document.documentElement||document.body,{childList:true,subtree:true});
            document.addEventListener('play',function(e){ var el=e.target; if(el&&(el.tagName==='AUDIO'||el.tagName==='VIDEO')&&window.__appMuted){ apply(el); } }, true);
          }
        }catch(e){}})();
        """
    }

    static let restoreNativeKeyboardScript: String = """
        (function(){ try{ var el = document.activeElement; if(el && (el.tagName==='INPUT' || el.tagName==='TEXTAREA')){ el.removeAttribute('readonly'); el.removeAttribute('inputmode'); el.style.caretColor=''; el.focus(); } }catch(e){} })();
    """

    static let blurActiveElementScript: String = """
        (function(){ try{ var el = document.activeElement; if(el && typeof el.blur === 'function'){ el.blur(); } }catch(e){} })();
    """
}
