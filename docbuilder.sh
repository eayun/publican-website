#!/bin/sh

source_url_base="https://github.com/eayun"
sources=("Documents" "Installation_Guide" "publican-eayun" "gitbook2publican")
documents=("original_dockbook/administrator-guide" "evaluation-guide" "FAQ" "quick-start-guide" "technical-reference-guide" "original_dockbook/user-guide" "V2V-guide" "original_dockbook/Developer-guide")
converted_documents=("administration-guide")

rc=0

case "$1" in
    getsource)
        workdir=$(pwd)
        for i in ${sources[@]}; do
            if [ -d $workdir/$i ]
            then
                cd $workdir/$i
                git reset --hard origin/master
                git clean -d -f
                git pull
            else
                cd $workdir
                git clone ${source_url_base}/$i
            fi
        done
        ;;
    buildwebsite)
        workdir=$(pwd)
        if [ -d publican-eayun -a -d Installation_Guide -a -d Documents -a -d gitbook2publican ]
        then
            rm -rf $workdir/web
            publican create_site --lang=zh-CN --site_config=$workdir/web/publican.cfg --db_file=$workdir/web/doc.db --toc_path=$workdir/web
            cd $workdir/publican-eayun
            publican build --quiet --formats=xml --langs=zh-CN --publish && publican install_brand --quiet --path=$workdir/web
            cd $workdir/Installation_Guide
            publican build --formats=html,html-single,epub,pdf --langs=zh-CN --quiet --publish --embedtoc && publican install_book --quiet --site_config=$workdir/web/publican.cfg --lang=zh-CN
            for i in ${documents[@]}; do
                cd $workdir/Documents/$i
                publican build --formats=html,html-single,epub,pdf --langs=zh-CN --quiet --publish --embedtoc && publican install_book --quiet --site_config=$workdir/web/publican.cfg --lang=zh-CN
            done
            for i in ${converted_documents[@]}; do
                cd $workdir/Documents/$i
                $workdir/gitbook2publican/auto.sh
                cd $workdir/Documents/$i/docbook/docbook/
                publican build --formats=html,html-single,epub,pdf --langs=zh-CN --quiet --publish --embedtoc && publican install_book --quiet --site_config=$workdir/web/publican.cfg --lang=zh-CN
            done
        else
            echo $"please prepare sources using '$0 getsource'"
            rc=3
        fi
        ;;
    package)
        workdir=$(pwd)
        if [ -d web ]
        then
            if [ $# = 3 ]
            then
                cd $workdir/web

                # dirty utf8 hack for publican
                title=$(echo "$3"|perl -MEncode -Mutf8 -ne 'map {if ($_>128) {print "\\\\u", sprintf( "%x", $_ )} else {print pack("U", $_)}} unpack( "U*", decode("utf8", $_));')

                sed '/^web_style/d' -i $workdir/web/publican.cfg
                echo $"web_style: 2" >> $workdir/web/publican.cfg

                sed '/^host/d' -i $workdir/web/publican.cfg
                echo $"host: \"$2\"" >> $workdir/web/publican.cfg

                sed '/^title/d' -i $workdir/web/publican.cfg
                echo $"title: \"$title\"" >> $workdir/web/publican.cfg
                publican update_site --site_config=$workdir/web/publican.cfg

                # fix symlink issue
                ln -sf default.js toc.js
                # fix title string in html & xml, js accepts "\uXXXX" so fix is not needed
                find -name "index.html" -exec sed -i "s/$title/$3/g" {} \;
                sed -i "s/$title/$3/g" opds.xml

                cd $workdir
                tar -c --exclude web/publican.cfg --exclude web/doc.db -zf web.tar.gz web/
            else
                echo $"Usage: $0 package <HOST> <TITLE>"
                rc=5
            fi
        else
            echo $"please build website using '$0 buildwebsite'"
            rc=4
        fi
        ;;
    *)
        echo $"Usage: $0 {getsource|buildwebsite|package}"
        exit 2
esac

exit $rc
